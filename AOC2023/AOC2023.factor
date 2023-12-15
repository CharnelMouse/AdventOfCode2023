USING: accessors arrays assocs backtrack combinators
compiler.utilities grouping hashtables io io.encodings.utf8
io.files kernel math math.functions math.order math.parser
math.vectors namespaces prettyprint quotations ranges regexp
sequences sorting splitting strings unicode vectors ;
FROM: math.statistics => histogram ;
FROM: multiline => /* ;
FROM: sequences.extras => first= second= last= 3map-reduce index* 2map-sum exchange-subseq ;
FROM: match => ?rest ;
FROM: math.combinatorics => nCk ;
FROM: sets => intersect union ;
IN: AOC2023

! Common words

: read-txt ( path -- seq ) utf8 [ read-lines ] with-file-reader ;
: read-input ( n -- seq ) number>string 2 CHAR: 0 pad-head ".txt" append read-txt ;
: as-seq ( x -- seq ) 1array ;
: replace-nth ( new n seq -- seq' ) [ 1array ] 2dip [ dup 1 + ] dip replace-slice ;
: split-words-multspace ( seq -- seq ) split-words harvest ;
: cut-paragraph ( strings -- paragraph rest-strings ) { "" } split1 ;
: parse-nums ( string -- ns ) split-words [ string>number ] map ;
: firsts ( seqs -- seq ) [ first ] map ;
: seconds ( seqs -- seq ) [ second ] map ;
: partition-by ( seq quot: ( elt -- key ) -- seqs ) collect-by >alist ; inline
: manhattan-distance ( pos pos -- n ) [ - abs ] 2map sum ;
: unordered-pairs ( seq -- pairs ) dup length <iota> dup [ 2array ] cartesian-map concat [ first2 < ] filter [ [ swap nth ] with map ] with map ;
: map-unordered-pairs ( seq quot: ( x x -- x ) -- seq' ) [ unordered-pairs ] dip [ first2 ] prepose map ; inline
: map-sum-unordered-pairs ( seq quot: ( x x -- x ) -- seq' ) [ unordered-pairs ] dip [ first2 ] prepose map-sum ; inline
: while-nonempty ( .. seq quot: ( .. seq -- .. seq ) -- .. seq ) [ dup empty? not ] swap while ; inline
: with-indices ( seq -- seq ) [ 2array ] { } map-index-as ;
: indices-where ( seq quot: ( el -- ? ) -- ns ) [ with-indices ] dip [ first ] prepose filter seconds ; inline
: ?but-last ( seq -- headseq/f ) [ f ] [ but-last ] if-empty ;
: #= ( x -- ? ) CHAR: # = ;
: .= ( x -- ? ) CHAR: . = ;
: O= ( x -- ? ) CHAR: O = ;


! Day 1

: digit-names ( -- seq ) { "zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine" } ;
: digit-strings ( -- seq ) 9 [0..b] [ number>string ] map ;

TUPLE: state text success ;
C: <state> state

: update-state ( string object ? -- state ) [ nip t ] [ drop f ] if <state> ;
: check-start ( state sub -- state ) over success>> [ drop ] [ [ text>> ] dip 2dup head? update-state ] if ;
: check-end ( state sub -- state ) over success>> [ drop ] [ [ text>> ] dip 2dup tail? update-state ] if ;
: check-matchers ( state seq quotation -- state ) swapd reduce ; inline
: check-word-starter ( state -- state ) digit-names [ check-start ] check-matchers ;
: check-word-ender ( state -- state ) digit-names [ check-end ] check-matchers ;
: check-num-starter ( state -- state ) digit-strings [ check-start ] check-matchers ;
: check-num-ender ( state -- state ) digit-strings [ check-end ] check-matchers ;
: check-starter ( state -- state ) check-word-starter check-num-starter ;
: check-ender ( state -- state ) check-word-ender check-num-ender ;

: not-found? ( state -- ? ) [ text>> empty? ] [ success>> ] bi or not ;
: find-first-word-loop ( state -- state ) check-starter dup success>> [ ] [ dup text>> rest over text<< ] if ;
: first-match ( string -- string ) f <state> [ dup not-found? ] [ find-first-word-loop ] while text>> ;
: find-last-word-loop ( state -- state ) check-ender dup success>> [ ] [ dup text>> but-last over text<< ] if ;
: last-match ( string -- string ) f <state> [ dup not-found? ] [ find-last-word-loop ] while text>> ;

: name-cases ( -- seq ) digit-names 9 [0..b] [ 1quotation ] map [ 2array ] 2map ;
: cases ( -- seq ) name-cases { [ string>number ] } append ;
: resolve ( string -- n ) cases [ case ] call( string seq -- n ) ;

: to-num ( string -- n ) [ digit? ] [ find nip ] [ find-last nip ] 2bi 2array string>number ;
: to-num2 ( string -- n ) [ first-match resolve 10 * ] [ last-match resolve ] bi + ;

: run-01-1 ( seq -- n ) [ to-num ] map-sum ;
: run-01-2 ( seq -- n ) [ to-num2 ] map-sum ;

: run-01 ( -- ) 1 read-input [ run-01-1 . ] [ run-01-2 . ] bi ;


! Day 2

: max-nth ( seq new n -- seq' ) [ 2dup nth ] dip max -rot replace-nth ;
: empty-bag ( -- bag ) { 0 0 0 } ;
: bag-power ( bag -- n ) product ;
: colour>n ( string -- n ) { { "red" [ 0 ] } { "green" [ 1 ] } { "blue" [ 2 ] } } case ;
: inc-bag ( bag seq -- bag' ) [ first string>number ] [ second colour>n ] bi -rot max-nth ;
: to-bag ( string -- bag ) "," split [ rest split-words ] map empty-bag [ inc-bag ] reduce ;
: to-bags ( string -- seq ) ":;" split rest [ to-bag ] map ;
: min-bag ( string -- bag ) to-bags empty-bag [ vmax ] reduce ;
: valid ( string bag -- ? ) [ min-bag ] dip [ <= ] 2all? ;
: n-if-valid ( string n bag -- n ) swapd valid [ 1 + ] [ drop 0 ] if ;

: run-02-1 ( seq -- n ) [ { 12 13 14 } n-if-valid ] map-index 0 [ + ] reduce ;
: run-02-2 ( seq -- f ) [ min-bag bag-power ] map-sum ;
: run-02 ( -- ) 2 read-input [ run-02-1 . ] [ run-02-2 . ] bi ;


! Day 3 ( nb refers to numblock, a continguous digit position set that will make a number )
! Most of the runtime is spent checking for adjacency. We might be able
! to cut down on this with some pre-processing, and working with only numblocks
! and their non-empty neighbours.

TUPLE: pos { x integer read-only } { y integer read-only } ; 
C: <pos> pos

: period? ( char -- ? ) CHAR: . = ;
: nonpersymb? ( char -- ? ) [ digit? ] [ period? ] bi or not ;
: gear? ( char -- ? ) CHAR: * = ;

: last-append ( seq x -- 1seq ) as-seq [ last ] dip append ;
: add-to-last ( seq x -- seq' ) [ last-append ] curry [ length 1 - ] [ ] tri replace-nth ;
: new-subseq ( seq -- seq' ) { { } } append ;
: split-on-false ( seq n/f -- seq ) dup [ add-to-last ] [ drop new-subseq ] if ;
: group-nonfalse ( seq -- subseqs ) { { } } [ split-on-false ] reduce harvest ;
: digit/f ( char n -- char/f ) swap digit? [ ] [ drop f ] if ;
: digit-slices ( string -- index-slices ) [ digit/f ] { } map-index-as group-nonfalse ;

: index/f ( x y quot: ( x -- ? ) -- ) dip swap [ ] [ drop f ] if ; inline
: true-index ( seq quot: ( x -- ? ) -- seq ) [ index/f ] curry { 0 } map-index-as ; inline
: slice-true ( seq quot: ( x -- ? ) -- seq ) true-index [ number? ] filter ; inline

: nonpersymb-indices ( seq<a> -- seq<a> ) [ nonpersymb? ] slice-true ;
: gear-indices ( seq -- seq ) [ gear? ] slice-true ;
: get-pos ( string n quot: ( seq -- seq ) -- seq ) dip [ <pos> ] curry map ; inline
: with-y ( n -- pos ) [ <pos> ] curry ; inline
: get-pos-set ( seq n quot: ( seq -- subseqs ) -- seq ) dip [ with-y map ] curry map ; inline
: numblocks-row ( string n -- nbs ) [ digit-slices ] get-pos-set ;
: sym-poss ( string n -- poss ) [ nonpersymb-indices ] get-pos ;
: gear-poss ( string n -- poss ) [ gear-indices ] get-pos ;
: numblocks ( strings -- nbs ) [ numblocks-row ] map-index concat ;
: symbol-positions ( strings -- poss ) [ sym-poss ] map-index concat ;
: gear-positions ( strings -- poss ) [ gear-poss ] map-index concat ;

: bi@diff1 ( x1 x2 quot: ( x -- n ) -- ? ) bi@ - abs 1 <= ; inline
: L1-dist1 ( pos pos -- ? ) [ [ x>> ] bi@diff1 ] [ [ y>> ] bi@diff1 ] 2bi and ;
: adjacent? ( nb pos -- ? ) [ L1-dist1 ] curry any? ;
: adjacent ( nbs pos -- nbs ) [ adjacent? ] curry filter ;
: adjacent-any? ( nb poss -- ? ) [ adjacent? ] with any? ;
: adjacent-any ( nbs poss -- nbs ) [ adjacent-any? ] curry filter ;
: adjacent-per-pos ( nbs poss -- nbs ) [ adjacent ] with map ;
: xbounds ( nb -- n n' ) [ first x>> ] [ last x>> 1 + ] bi ;
: num ( nb strings -- int ) over first y>> swap nth [ xbounds ] dip subseq string>number ;
: num-lookup ( strings -- quot: ( poss -- int ) ) [ num ] curry ; inline

: valid-nbs ( strings -- nbs ) [ numblocks ] [ symbol-positions ] bi adjacent-any ;
: gear-nb-sets ( strings -- nb-sets ) [ numblocks ] [ gear-positions ] bi adjacent-per-pos ;
: gear-nb-pairs ( strings -- nb-pairs ) gear-nb-sets [ length 2 = ] filter ;
: with-lookup ( strings quot -- object quot' ) [ num-lookup ] bi ; inline

: run-03-1 ( strings -- n ) [ valid-nbs ] with-lookup map-sum ;
: run-03-2 ( strings -- n ) [ gear-nb-pairs ] with-lookup [ map ] curry map [ product ] map-sum ;
: run-03 ( -- ) 3 read-input [ run-03-1 . ] [ run-03-2 . ] bi ;


! Day 4

: -cardname ( card -- string ) ":" split second ;
: cardhalves ( string -- pair ) "|" split [ split-words-multspace ] map ;
: cardnmatch ( pair -- n ) [ first ] [ second ] bi intersect length ;
: card-matches ( card -- n ) -cardname cardhalves cardnmatch ;
: matchval ( n -- n ) dup 0 = [ drop 0 ] [ 1 - 2^ ] if ;
: card-value ( card -- n ) card-matches matchval ;

: 1s ( cards -- counts ) [ drop 1 ] { 0 } map-as ;
: set-slice ( new old -- ) [ over set-first rest-slice ] reduce drop ;
: inc-slice ( n slice -- ) dup empty? [ 2drop ] [ [ swap [ + ] curry map ] keep set-slice ] if ;
: stepstate ( slice n -- rest-slice' ) [ [ rest-slice ] [ first ] [ length 1 - ] tri ] dip min overd head-slice inc-slice ;

: run-04-1 ( cards -- n ) [ card-value ] map-sum ;
: run-04-2 ( cards -- n ) [ 1s ] [ [ card-matches ] map ] bi over [ stepstate ] reduce drop sum ;
: run-04 ( -- ) 4 read-input [ run-04-1 . ] [ run-04-2 . ] bi ;

! Day 5

: lengthed-range ( start length -- range ) over + [a..b) ;
: empty-range ( -- range ) T{ range { step 1 } } ;
: permdiff ( perm -- n ) [ first ] [ second ] bi - ;

: parse-seeds ( string -- seeds ) first split-words rest [ string>number ] map ;
: parse-seed-ranges ( string -- seed-ranges ) parse-seeds 2 group [ [ first ] [ second ] bi lengthed-range ] map ;
: cut-seeds ( strings -- seeds strings ) cut-paragraph [ parse-seeds ] dip ;
: cut-seed-ranges ( strings -- seed-ranges strings ) cut-paragraph [ parse-seed-ranges ] dip ;

: clean ( x -- x-f ) f 2array ;
: dirty ( x -- x-t ) t 2array ;
: remove-flag ( x-? -- x ) first ;
: dirty? ( x-? -- ? ) second ;
: clean? ( x-? -- ? ) second not ;

: if-clean ( x-? clean: ( x-? -- x-? ) dirty: ( x-? -- x-? ) -- x-? ) pick clean? -rot if ; inline

: within? ( n range-string -- ? ) [ second - ] [ third nip ] 2bi [ drop 0 >= ] [ < ] 2bi and ;
: source-range ( map-range -- source-range ) [ second ] [ third ] bi lengthed-range ;
: cut-last ( ranges -- ranges last-range ) dup length 1 - cut-slice first ;
: cut-slice-at ( range/slice value -- before after ) over first [-] index-or-length cut-slice ;
: split-last ( ranges splitter -- ranges ) [ cut-last ] dip over ?first [ cut-slice-at ] [ 2drop { } { } ] if [ 1array append ] bi@ ;
: split-by-range ( range splitter-range -- 3ranges ) [ first ] [ last 1 + ] bi 2array swap 1array [ split-last ] reduce ;
: split-by-perm ( range perm -- 3ranges ) source-range split-by-range ;
: shift-range ( range n -- range ) over empty? [ drop ] [ [ [ first ] dip + ] [ drop length ] 2bi lengthed-range ] if ;
: inc-range ( range perm -- range ) permdiff shift-range ;
: inc-middle-range ( 3ranges perm -- 3ranges ) [ [ second ] dip inc-range 1 ] keepd replace-nth ;
: c-d-c ( 3array -- 3array ) { f t f } [ 2array ] 2map ;
: reject-empty ( seq<range-?> -- seq<range-?> ) [ first empty? ] reject ;

: ap-n ( n perm -- n-? ) 2dup within? [ permdiff + dirty ] [ drop clean ] if ;
: apply-perm-n ( n-f perm -- n-? ) [ remove-flag ] dip ap-n ;
: apply-perm-if-clean-n ( n-? perm -- n-? ) [ apply-perm-n ] curry [ ] if-clean ;
: bind-range-n ( seq<n-?> perm-string -- seq<n-?> ) parse-nums [ apply-perm-if-clean-n ] curry map ;
: apply-map-n ( ns map -- ns ) rest swap [ clean ] map [ bind-range-n ] reduce [ remove-flag ] map ;
: next-map-n ( ns maps -- ns rest-maps ) cut-paragraph [ apply-map-n ] dip ;
: run-05-1 ( strings -- n ) cut-seeds [ next-map-n ] while-nonempty drop infimum ;

: ap-r ( range perm -- seq<range-?> ) [ split-by-perm ] keep inc-middle-range c-d-c reject-empty ;
: apply-perm-r ( r-f perm -- seq<r-?> ) [ remove-flag ] dip ap-r ;
: apply-perm-if-clean-r ( r-? perm -- seq<r-?> ) [ apply-perm-r ] curry [ as-seq ] if-clean ;
: bind-range-r ( seq<r-?> perm-string -- seq<r-?> ) parse-nums [ apply-perm-if-clean-r ] curry map concat ;
: apply-map-r ( rs map -- rs ) rest swap [ clean ] map [ bind-range-r ] reduce [ remove-flag ] map ;
: next-map-r ( rs maps -- rs rest-maps ) cut-paragraph [ apply-map-r ] dip ;
: run-05-2 ( strings -- n ) cut-seed-ranges [ next-map-r ] while-nonempty drop firsts infimum ;

: run-05 ( -- ) 5 read-input [ run-05-1 . ] [ run-05-2 . ] bi ;


! Day 6

: parse-06 ( strings -- times distances ) [ split-words-multspace rest [ string>number ] map ] map first2 ;
: parse-06-single ( strings -- time distance ) [ split-words-multspace rest concat string>number ] map first2 ;
: inv-parts ( time distance -- centre radius ) [ 2 / dup sq ] dip - sqrt ;
: open-members ( centre radius -- n ) [ + 1 - ceiling >fixnum 1 + ] [ - 1 + floor >fixnum ] 2bi [-] ;
: button-times ( time distance -- n ) inv-parts open-members ;
: run-06-1 ( strings -- n ) parse-06 [ button-times ] [ * ] 2map-reduce ;
: run-06-2 ( strings -- n ) parse-06-single button-times ;
: run-06 ( -- ) 6 read-input [ run-06-1 . ] [ run-06-2 . ] bi ;


! Day 7

: parse-07 ( strings -- pairs ) [ split-words first2 [ [ 1string ] { } map-as ] dip string>number 2array ] map ;
: type2 ( hist -- type ) values 4 swap member? 6 5 ? ;
: type3 ( hist -- type ) values 3 swap member? 4 3 ? ;
: hist-type ( hist -- type ) dup >alist length { { 1 [ drop 7 ] } { 2 [ type2 ] } { 3 [ type3 ] } { 4 [ drop 2 ] } { 5 [ drop 1 ] } } case ;
: picture-value ( card -- n ) { { CHAR: A [ 14 ] } { CHAR: T [ 10 ] } { CHAR: J [ 11 ] } { CHAR: Q [ 12 ] } { CHAR: K [ 13 ] } } case ;
: card-rank ( card -- n ) dup digit? [ 1string string>number ] [ picture-value ] if ;
: ranks ( hand -- ns ) concat [ card-rank ] { } map-as ;
: pair-value ( pair n -- n ) [ second ] dip 1 + * ;
: hand-type ( pair prep: ( hand -- hand ) -- type ) [ first histogram ] dip call hist-type ; inline
: hand-ranks ( pair prep: ( card -- card ) -- ns ) [ first ] dip map ranks ; inline
: sort-by-hand ( pairs hand-prep: ( hand-hist -- hand-alist ) card-prep: ( card -- card ) -- pairs ) [ [ hand-type ] curry partition-by ] dip [ [ hand-ranks ] curry [ sort-by ] curry [ second ] swap compose call( pair -- pairs ) ] curry map concat ; inline

: best-card ( hist -- card ) >alist dup values supremum [ second= ] curry filter keys [ first card-rank ] supremum-by ;
: add-free ( hist n -- alist ) [ dup best-card 2dup swap at ] dip + set-of ;
: free-hand ( n -- alist ) "A" swap 2array 1array ;
: best-hand ( hist n-free -- alist ) [ >alist ] dip over length 0 > [ add-free ] [ nip free-hand ] if ;
: Js-to-best ( hist -- alist ) "J" over delete-at* [ best-hand ] [ drop ] if ;
: J-to-0 ( card -- card ) dup "J" = [ drop "0" ] when ;

: run-07-1 ( strings -- n ) parse-07 [ ] [ ] sort-by-hand [ pair-value ] map-index sum ;
: run-07-2 ( strings -- n ) parse-07 [ Js-to-best ] [ J-to-0 ] sort-by-hand [ pair-value ] map-index sum ;
: run-07 ( -- ) 7 read-input [ run-07-1 . ] [ run-07-2 . ] bi ;


! Day 8
! split-indices and last-index are big time sinks in parts 1 and 2 respectively.
! The former might be better with slices, I'm not sure about the latter.

/*
Modular arithmetic:
x = a mod b, x = c mod d => x = a + br = c + ds for some r,s >= 0.
If ub + vd = 1, then x = ubx + vdx = ub(c+ds) + vd(a+br) = vda + ubc + (us + rv)bd, so z = vda + ubc mod bd.
If ub + vd = z, where z = gcd(b,d), then zx = ubx + vdx = ub(c+ds) + vd(a+br) = vda + ubc + (us + rv)bd,
so x = ( vda + ubc )/z mod lcm(b,d).
*/

/*
The documentation for gcd is wrong: a is actually the required multiplier for ax = d mod y, not ay = d mod x.
Example code to show this:
USE: backtrack
: check-gcd ( x y -- ? ) 2dup gcd [ * ] dip - swap mod 0 = ;
: check-gcd-opp-spec ( x y -- ? ) [ swap ] [ gcd ] 2bi [ * ] dip - swap mod 0 = ;
[ 1 30 [a..b] amb 1 30 [a..b] amb 2dup check-gcd not must-be-true 2array . t ] [ "All good." print ] if-amb drop
[ 1 30 [a..b] amb 1 30 [a..b] amb 2dup check-gcd-opp-spec not must-be-true 2array . t ] [ "All good." print ] if-amb drop
*/

:: mults ( gcd mult1 x y -- mult2 ) gcd x mult1 * - y / ;
:: crt-mod ( mod1 xs1 mod2 xs2 -- newmod xs )
  mod1 mod2 gcd :> ( mult1 d )
  d mult1 mod1 mod2 mults :> mult2
  mod1 mod2 * d / :> newmod
  xs1 xs2 [ 2array ] cartesian-map concat [ first2 [ d rem ] same? ] filter :> xpairs
  xpairs [ first2 [ mod2 * mult2 * ] dip mod1 * mult1 * + d / newmod rem ] map unique keys :> xs
  newmod xs ;
: combine-congruences ( cong1 cong2 -- new-cong ) [ first2 ] bi@ crt-mod 2array ;

: dir-to-index ( char -- n ) CHAR: L = 0 1 ? ;
: parse-network ( strings -- network ) [ [ "(,)" member? ] reject split-words first4 [ drop ] 2dip 2array 2array ] map >hashtable ;
: parse-08 ( strings -- directions network ) cut-paragraph [ first [ dir-to-index ] { 0 } map-as ] dip parse-network ;

! Assuming no finish before all in cycle

: next-turn ( turns -- turns' turn ) { 1 } split-indices first2 over append swap first ;
: apply-turn ( turn map loc -- map loc' ) over at swapd nth ;
: next-move ( turns map loc steps -- turns' map loc' steps' ) [ next-turn ] 3dip [ apply-turn ] dip 1 + ;
: run-08-1 ( strings -- n ) parse-08 "AAA" 0 [ over "ZZZ" = ] [ next-move ] until [ 3drop ] dip ;

: <path-buckets> ( n -- seq ) { } <repetition> >array ;
:: suffix-nth ( el seq index -- seq' ) index seq tuck nth el suffix index seq set-nth ;
:: move-08 ( path network directions index -- path' network directions index' n/? )
  index path nth last :> old-loc
  index 1 + directions length mod :> new-index
  index directions nth :> direction
  direction old-loc network at nth :> new-loc
  new-loc new-index path nth last-index :> prev-match
  prev-match
    [ path network directions index prev-match ]
    [ new-loc path new-index suffix-nth network directions new-index f ]
  if ;
: cycle-start ( start-loop ndir end-index -- n ) 1 + over rem [ * ] dip + ;
: leadin-time ( path -- n ) first length ;
: path-arr ( path -- flat-path ) dup leadin-time [ f pad-tail [ 1vector ] map ] curry map unclip [ [ append! ] 2map ] reduce concat sift ;
: same-last ( cycle -- 1indexes ) [ with-indices ] [ last [ first= ] curry ] bi filter [ second 1 + ] map ;
: possible-groups ( cycle -- group-sets ) dup same-last dup last [ swap / ] curry map [ integer? ] filter over length [ swap / ] curry map swap [ swap <groups> ] curry map ;
: shorten-cycle ( cycle -- cycle ) possible-groups [ dup first [ = ] curry all? ] filter first first >array ;
: clean-path ( path start-loop ndir end-index -- clean-path ) [ path-arr ] 3dip cycle-start [ head ] [ tail shorten-cycle ] 2bi 2array ;
: move-until-cycle ( path network directions -- clean-path ) 0 f [ dup ] [ drop move-08 ] until [ nip length ] 2dip -rot clean-path ;

: starts ( map -- seq ) keys [ CHAR: A last= ] filter ;
:: paths ( directions network -- paths ) network starts [ 1array 0 directions length <path-buckets> [ set-nth ] keep ] map ;
: split-cycle ( n path -- path1 path2 ) tuck second length rem 1array [ second ] dip split-indices first2 ;
: nrot-seq ( n path -- path' ) tuck split-cycle over append [ [ first ] dip append ] dip 2array ;
: collapse-to-common-start ( paths -- leadin-time paths' ) [ [ leadin-time ] map [ supremum ] [ ] [ supremum ] tri [ swap - ] curry map ] keep [ nrot-seq ] 2map ;
: end-loc? ( string -- ? ) CHAR: Z last= ;
: end-indices ( seq -- ns ) [ end-loc? ] indices-where ;
: check-early-end ( paths -- cycles n/? ) [ seconds ] [ firsts ] bi [ end-indices ] map unclip [ union ] reduce dup empty? [ drop f ] [ first ] if ;
: end-cong ( cycle -- mod-vals-pair ) [ length ] [ end-indices ] bi 2array ;
: solve-cycles ( cycles -- n ) [ end-cong ] map unclip [ combine-congruences ] reduce second dup empty? [ ] when infimum ;

: run-08-2 ( strings -- n )
  parse-08
  2dup paths
  -rot swap [ move-until-cycle ] curry curry map
  collapse-to-common-start check-early-end dup [ nip ] [ drop solve-cycles ] if + ;
: run-08 ( -- ) 8 read-input [ run-08-1 . ] [ run-08-2 . ] bi ;


! Day 9

: all-equal? ( seq -- ? ) [ first ] keep swap [ = ] curry all? ;
: outer-nums ( seq -- pair ) dup all-equal? [ first dup 2array ] [ [ [ first ] [ last ] bi 2array ] [ 2 <clumps> [ first2 swap - ] map outer-nums { -1 1 } v* ] bi v+ ] if ;
: process-09 ( seqs -- pair ) [ outer-nums ] [ v+ ] map-reduce ;
: run-09-1 ( pair -- n ) second ;
: run-09-2 ( pair -- n ) first ;
: run-09 ( -- ) 9 read-input [ parse-nums ] map process-09 [ run-09-1 . ] [ run-09-2 . ] bi ;


! Day 10
! row-partial-at is slow, this would probably be quicker using part of the original input row.
! I'm also not sure that the hashmap is necessary.

: positions ( strings -- poss ) [ length [0..b) ] [ first length [0..b) ] bi [ swap 2array ] cartesian-map concat ;
: parse-10 ( strings -- map ) [ positions ] [ concat ] bi [ 2array ] 2map >hashtable ;

: up ( -- pair ) { 0 -1 } ; inline
: down ( -- pair ) { 0 1 } ; inline
: left ( -- pair ) { -1 0 } ; inline
: right ( -- pair ) { 1 0 } ; inline
: facing-lookup ( -- seq ) {
  { CHAR: | [ up down 2array ] }
  { CHAR: - [ right left 2array ] }
  { CHAR: L [ up right 2array ] }
  { CHAR: J [ up left 2array ] }
  { CHAR: 7 [ down left 2array ] }
  { CHAR: F [ right down 2array ] }
  { CHAR: S [ t ] }
  [ drop f ] } ; inline
: facings ( char -- pair/? ) facing-lookup case ;

: opposing? ( pair pair' -- ? ) v+ [ 0 = ] all? ;

: next-dir-in-loop ( dir-pos-val -- dir' ) first3 nip facings swap [ opposing? ] curry reject first ;
: next-in-loop ( hist dir-pos-val map -- hist' dir'-pos'-val'/f map )
  [ [ second ] keep ] dip ! ( hist pos dir-pos-val map )
  [ [ 2dup first= [ drop f ] [ suffix! t ] if ] keep ] 2dip ! ( hist' ? pos dir-pos-val map )
  [ rot ] dip swap ! ( hist' pos dir-pos-val map ? )
    [
      [ next-dir-in-loop ] dip ! ( hist pos dir' map )
      [ [ v+ ] keep ] dip ! ( hist pos' dir' map ) ;
      [ swap [ 2array ] keep ] dip ! ( hist dir'-pos' pos' map )
      [ at suffix ] keep ! ( hist dir'-pos'-val' map )
    ]
    [ [ 2drop f ] dip ] ! ( hist' f map )
  if ;

: compass-directions ( -- seq ) { { 0 -1 } { 1 0 } { 0 1 } { -1 0 } } ;
: mneighbours ( pos -- dir-pos-pairs ) compass-directions [ [ v+ ] keep swap 2array ] with map ;
: in-map ( map dir-pos-pairs -- dir-pos-val-triples ) swap [ dupd [ second ] dip ?at [ suffix ] [ 2drop f ] if ] curry map sift ;
: connects-in? ( dir-pos-val -- ? ) first3 nip facings dup [ swap [ opposing? ] curry any? ] [ 2drop f ] if ;
: valid-neighbours ( map pos -- dir-pos-val-s ) mneighbours in-map [ connects-in? ] filter ;
: find-start ( map -- pos )  [ keys ] [ values ] bi CHAR: S index* swap nth ;
: find-start-connections ( start map -- dir-pos-val-s ) swap valid-neighbours ;
: find-loop-from-pair ( start-connections start-pos map -- loop ) swapd [ 1vector ] 2dip [ over ] [ next-in-loop ] while 2drop ;
: find-loop ( map -- loop ) [ find-start ] keep dupd [ find-start-connections ] keep swapd [ find-loop-from-pair ] curry curry map [ ] find nip ;

: dirs-to-pipe ( dir1 dir2 -- char ) 2array sort {
    { { { -1 0 } { 0 -1 } } [ CHAR: J ] }
    { { { -1 0 } { 0 1 } } [ CHAR: 7 ] }
    { { { -1 0 } { 1 0 } } [ CHAR: - ] }
    { { { 0 -1 } { 0 1 } } [ CHAR: | ] }
    { { { 0 -1 } { 1 0 } } [ CHAR: L ] }
    { { { 0 1 } { 1 0 } } [ CHAR: F ] }
  } case ;
: get-start-pipe ( loop -- char ) [ [ second ] [ first ] bi v- ] [ [ last ] [ first ] bi v- ] bi dirs-to-pipe ;
: fix-start-pipe ( loop map -- map' ) [ [ get-start-pipe ] [ first ] bi ] dip ?set-at ;

: loop-bounds ( loop -- corners ) [ unclip [ vmin ] reduce ] [ unclip [ vmax ] reduce ] bi 2array ;

: partition-pipes-by-row ( loop -- row-cols-pairs ) [ second ] partition-by [ firsts sort ] assoc-map ;

: row-partial-at ( row hash -- hash' ) [ drop second= ] with assoc-filter [ [ first ] dip ] assoc-map ;
: to-range ( sorted-ns -- range ) [ first ] [ last ] bi [a..b] ;
: nonloop-weights ( cols pipe-cols -- seq ) [ member? 0 1 ? ] curry map ;
: char-halfval ( char -- n ) {
    { CHAR: | [ 2 ] }
    { CHAR: F [ 1 ] }
    { CHAR: 7 [ 1 ] }
    { CHAR: L [ -1 ] }
    { CHAR: J [ -1 ] }
    [ drop 0 ]
  } case ;
: halfturn ( col pipe-cols row-pipe-map -- ht ) [ dupd member? ] dip [ at char-halfval ] curry [ drop 0 ] if ;
: halfturns ( cols pipe-cols row-pipe-map -- hts ) [ halfturn ] 2curry map ;
: comb-hc ( hc1 hc2 -- newhc ) 2dup [ odd? ] both? [ - ] [ + ] if ;
: accumulate-halfturns ( hts -- turn-weights ) 0 [ comb-hc ] accumulate* [ 2 / floor 2 rem ] map ;
: count-internal ( row-cols pipe-map -- n )
  [ [ second [ to-range ] keep ] [ first ] bi ] dip row-partial-at
  [ halfturns accumulate-halfturns ] curry [ nonloop-weights ] 2bi
  [ * ] [ + ] 2map-reduce ;

: prepare-10 ( strings -- loop map ) parse-10 [ find-loop ] keep dupd fix-start-pipe ;
: run-10-1 ( loop map -- n ) drop length 2 / ;
: run-10-2 ( loop map -- n ) [ partition-pipes-by-row ] dip [ count-internal ] curry map-sum ;
: run-10 ( -- ) 10 read-input prepare-10 [ run-10-1 . ] [ run-10-2 . ] 2bi ;


! Day 11

: row-mults ( strings n -- mults ) [ 1 ? ] curry [ [ CHAR: . = ] all? ] prepose map ;
: col-mults ( strings n -- mults ) [ unclip [ CHAR: . = ] { } map-as [ [ CHAR: . = ] { } map-as [ and ] 2map ] reduce ] dip [ 1 ? ] curry map ;
: galaxies ( strings -- poss ) [ swap [ CHAR: # = ] indices-where [ swap 2array ] with map ] map-index concat ;
: weights-11 ( strings n -- xweights-yweights-pair ) [ [ col-mults ] curry ] [ [ row-mults ] curry ] bi bi 2array ;
: weighted-1d-distance ( x y weights -- n ) [ [ min ] [ max ] 2bi ] dip <slice> sum ;
: weighted-manhattan-distance ( pos pos weights -- n ) [ weighted-1d-distance ] [ + ] 3map-reduce ;

: process-11 ( strings -- galaxies strings ) [ galaxies ] keep ;
: run-11-n ( galaxies strings n -- n ) weights-11 [ weighted-manhattan-distance ] curry map-sum-unordered-pairs ;
: run-11-1 ( galaxies strings -- n ) 2 run-11-n ;
: run-11-2 ( galaxies strings -- n ) 1,000,000 run-11-n ;
: run-11 ( -- ) 11 read-input process-11 [ run-11-1 . ] [ run-11-2 . ] 2bi ;


! Day 12
! Half of the runtime is spent just getting subsequences, this might be removable by
! using slices instead ( no editing in place, though, we need the original when backtracking)

SYMBOL: cache-12
: prepare-12 ( string -- string lens ) split-words first2 "," split [ string>number ] map ;
: expand-12 ( string lens -- string*5 lens*5 ) [ 5 swap <repetition> "?" join ] dip 5 swap <repetition> concat ;
: trim-.s-head ( string -- string' ) [ CHAR: . = ] trim-head ;
: rest-if-nonempty ( string -- string' ) dup empty? [ rest ] unless ;
: cache-keep-12 ( val string lens -- val ) [ dup ] 2dip 2array cache-12 get set-at ;
: pass-12 ( string lens -- 1 ) [ 1 ] 2dip cache-keep-12 ;
: fail-12 ( string lens -- 0 ) [ 0 ] 2dip cache-keep-12 ;
: 2if-else-fail ( string lens cond: ( x y -- ? ) true: ( x y -- n ) -- n ) [ 2dup ] 2dip [ call ] dip [ fail-12 ] if ; inline
: quot-2-1 ( quot: ( x y -- z ) -- quot: ( x y -- z ) ) [ call( x x -- x ) ] curry ; inline
: if-not-cached-12 ( string lens notcached: ( string lens -- n ) -- n ) [ drop ] prepose [ ] curry [ 2dup 2array cache-12 get ?at [ 2nip ] ] prepose [ if ] compose call ; inline

: ?to. ( string -- string' ) rest ;
: ?to# ( string -- string' ) rest CHAR: # prefix ;
: enough#? ( string lens -- ? ) first head [ .= not ] all? ;
: next-emptyable? ( string lens -- ? ) first swap ?nth #= not ;
: fill-len ( string lens -- string' lens' ) unclip swap [ tail rest-if-nonempty ] dip ;

DEFER: 1solve-12-cached

: 1solve-cases-sum ( string lens -- n ) [ [ ?to. ] dip 1solve-12-cached ] [ [ ?to# ] dip 1solve-12-cached ] 2bi + ;
: .case-12 ( string lens -- n ) [ trim-.s-head ] dip 1solve-12-cached ;
: #case-12 ( string lens -- n ) [ [ enough#? ] [ next-emptyable? ] 2bi and ] [ fill-len 1solve-12-cached ] 2if-else-fail ;
: ?case-12 ( string lens -- n ) [ 1solve-cases-sum ] 2keep cache-keep-12 ;
: process-next-char ( string lens -- n ) over first { { CHAR: . [ .case-12 ] } { CHAR: # [ #case-12 ] } { CHAR: ? [ ?case-12 ] } } case ;

: no-#s? ( string -- ? ) [ #= not ] all? ;
: success-by-no-#s ( string -- n ) dup no-#s? [ { } pass-12 ] [ { } fail-12 ] if ;
: enough-room? ( string lens -- ? )  [ length ] dip [ sum ] [ length 1 - ] bi + >= ;
: 1solve-12-cached ( string lens -- n ) [ [ success-by-no-#s ] [ [ enough-room? ] [ process-next-char ] 2if-else-fail ] if-empty ] if-not-cached-12 ;

: solve-12 ( string lens -- n ) { } >hashtable cache-12 set [ 1solve-12-cached ] 2curry bag-of sum ;
: run-12-1 ( strings -- n ) [ prepare-12 solve-12 ] map-sum ;
: run-12-2 ( strings -- n ) [ prepare-12 expand-12 solve-12 ] map-sum ;
: run-12 ( -- ) 12 read-input [ run-12-1 . ] [ run-12-2 . ] bi ;


! Day 13

: init-line ( seq -- pair ) unclip "" swap prefix 2array ;
: line-end? ( pair -- ? ) first empty? ;
: move-line ( pair -- pair' ) first2 [ unclip ] dip swap prefix 2array ;

: mirror? ( pair -- ? ) first2 [ head? ] [ swap head? ] 2bi or ;
: mirror-pos ( seq -- n ) first second length ;
: ?mirror-pos ( seq -- n/? ? ) [ first second length ] [ first first length ] bi 0 = [ drop f f ] [ t ] if ;
: ?hline ( strings -- n/? ? ) flip [ init-line ] map [ dup [ [ mirror? ] [ line-end? ] bi or ] all? ] [ [ move-line ] map ] until ?mirror-pos ;
: score-hline ( hline -- n ) 100 * ;
: vline ( strings -- n ) [ init-line ] map [ dup [ mirror? ] all? ] [ [ move-line ] map ] until mirror-pos ;
: score-vline ( vline -- n ) ;
: score-reflection ( strings -- n ) dup ?hline [ nip score-hline ] [ drop vline score-vline ] if ;

: mirror-line-hdist ( pair -- n ) first2 2dup min-length [ [ head ] curry bi@ [ = 1 0 ? ] 2map-sum ] keep swap - ;
: log-mirror-line-hdist ( bits pair -- bits' ) mirror-line-hdist suffix ;
: smudge-line-hdists ( string -- dists ) init-line { } swap [ log-mirror-line-hdist ] keep [ dup line-end? ] [ move-line [ log-mirror-line-hdist ] keep ] until drop ;
: smudge-hdists ( strings -- dists ) [ smudge-line-hdists ] [ v+ ] map-reduce ;
: find-best ( tallies -- n/f f ) [ 1 = ] find-last [ dup [ 1 + ] when ] dip ;
: smudge-distances ( strings -- hdists vdists ) [ flip smudge-hdists ] [ smudge-hdists ] bi ;
: smudge ( hdists vdists -- n hline? ) find-best [ nip f ] [ drop find-best drop t ] if ;
: score-smudged-reflection ( n hline? -- n ) [ 100 * ] when ;

: run-13-1 ( strings -- n ) { "" } split [ score-reflection ] map-sum ;
: run-13-2 ( string -- n ) { "" } split [ smudge-distances smudge score-smudged-reflection ] map-sum ;
: run-13 ( -- ) 13 read-input [ run-13-1 . ] [ run-13-2 . ] bi ;


! Day 14
! half the time is spent
! writing more direct versions of tilt-N/E/S instead of
! routing everything through tilt-W would probably speed things
! up a lot

CONSTANT: 1bil 1,000,000,000
SYMBOL: cache-14
: reset-cache-14 ( -- ) { } cache-14 set ;
: suffix-cache-14 ( x -- ) [ cache-14 get ] dip suffix cache-14 set ;

: find-next-. ( from seq -- seq i elt ) tuck dup empty? [ 2drop f f ] [ [ .= ] find-from ] if ;
: find-next-non. ( from seq -- i elt ) [ .= not ] find-from ;
: find-O-end ( from seq -- i elt ) [ O= not ] find-from ;

: min-difference ( ind1 ind2 ind3 -- n ) [ [ swap - ] keep ] dip swap - min ;
:: swap-.s-with-Os ( .-from O-from seq -- seq' new-.-from )
  O-from seq find-O-end [ drop seq length ] unless :> O-after
  .-from O-from O-after min-difference
  .-from [ O-from seq [ exchange-subseq ] keep ] [ + ] 2bi ;
: swap-.s-with-Os-if-next ( .-from seq -- seq' new-from/f ) 2dup find-next-non. swapd O= [ swap-.s-with-Os ] [ [ drop ] 2dip swap ] if ;
: 1tilt-west ( string -- string' ) 0 [ dup [ swap find-next-. ] [ f ] if ] [ swap swap-.s-with-Os-if-next ] while drop ;

: tilt-west ( strings -- strings' ) [ 1tilt-west ] map ;
: tilt-north ( strings -- strings' ) flip tilt-west flip ;
: tilt-east ( strings -- strings' ) [ reverse ] map tilt-west [ reverse ] map ;
: tilt-south ( strings -- strings' ) flip tilt-east flip ;
: cycle ( strings -- strings' ) tilt-north tilt-west tilt-south tilt-east ;

: from-last ( seq el -- seq' ) dupd [ = ] curry find-last drop tail ;
: end-or-repeat? ( n strings -- ? ) [ 1bil = ] dip cache-14 get member? or ;
: cycle-until-finished-or-repeat ( strings -- n strings' ) reset-cache-14 0 swap [ 2dup end-or-repeat? ] [ dup suffix-cache-14 cycle [ 1 + ] dip ] until ;
: skip-rest-cycles ( n strings -- strings' ) [ 1bil swap - cache-14 get ] dip from-last [ length mod ] keep nth ;

: north-load ( strings -- n ) flip [ reverse [ CHAR: O = ] indices-where [ 1 + ] map-sum ] map-sum ;

: run-14-1 ( strings -- n ) tilt-north north-load ;
: run-14-2 ( strings -- n ) cycle-until-finished-or-repeat skip-rest-cycles north-load ;
: run-14 ( -- ) 14 read-input [ run-14-1 . ] [ run-14-2 . ] bi ;
