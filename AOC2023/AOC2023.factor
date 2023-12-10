USING: io.encodings.utf8 io.files io unicode sequences strings kernel math.parser ranges quotations arrays combinators regexp math prettyprint accessors splitting math.order sets grouping math.functions grouping.extras assocs sorting hashtables compiler.utilities math.vectors ;
FROM: math.statistics => histogram ;
FROM: multiline => /* ;
IN: AOC2023

! Common words

: read-input ( path -- seq ) utf8 [ read-lines ] with-file-reader ;
: as-seq ( x -- seq ) 1array ;
: replace-nth ( new n seq -- seq' ) [ 1array ] 2dip [ dup 1 + ] dip replace-slice ;
: split-words-multspace ( seq -- seq ) split-words harvest ;
: cut-paragraph ( strings -- paragraph rest-strings ) { "" } split1 ;
: parse-nums ( string -- ns ) split-words [ string>number ] map ;
: firsts ( seqs -- seq ) [ first ] map ;
: seconds ( seqs -- seq ) [ second ] map ;


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

: read-01 ( -- seq ) "01.txt" read-input ;
: run-01-1 ( seq -- n ) [ to-num ] map-sum ;
: run-01-2 ( seq -- n ) [ to-num2 ] map-sum ;

: run-01 ( -- ) read-01 [ run-01-1 . ] [ run-01-2 . ] bi ;


! Day 2

: max-nth ( seq new n -- seq' ) [ 2dup nth ] dip max -rot replace-nth ;
: empty-bag ( -- bag ) { 0 0 0 } ;
: bag-power ( bag -- n ) product ;
: colour>n ( string -- n ) { { "red" [ 0 ] } { "green" [ 1 ] } { "blue" [ 2 ] } } case ;
: inc-bag ( bag seq -- bag' ) [ first string>number ] [ second colour>n ] bi -rot max-nth ;
: to-bag ( string -- bag ) "," split [ rest split-words ] map empty-bag [ inc-bag ] reduce ;
: to-bags ( string -- seq ) ":;" split rest [ to-bag ] map ;
: bag-max ( bag bag' -- bag'' ) [ max ] 2map ;
: min-bag ( string -- bag ) to-bags empty-bag [ bag-max ] reduce ;
: valid ( string bag -- ? ) [ min-bag ] dip [ <= ] 2all? ;
: n-if-valid ( string n bag -- n ) swapd valid [ 1 + ] [ drop 0 ] if ;

: read-02 ( -- seq ) "02.txt" read-input ;
: run-02-1 ( seq -- n ) [ { 12 13 14 } n-if-valid ] map-index 0 [ + ] reduce ;
: run-02-2 ( seq -- f ) [ min-bag bag-power ] map-sum ;
: run-02 ( -- ) read-02 [ run-02-1 . ] [ run-02-2 . ] bi ;


! Day 3 ( nb refers to numblock, a continguous digit position set that will make a number )

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

: bi@diff1 ( quot: ( x -- n ) -- ? ) bi@ - abs 1 <= ; inline
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

: read-03 ( -- strings ) "03.txt" read-input ;
: run-03-1 ( strings -- n ) [ valid-nbs ] with-lookup map-sum ;
: run-03-2 ( strings -- n ) [ gear-nb-pairs ] with-lookup [ map ] curry map [ product ] map-sum ;
: run-03 ( -- ) read-03 [ run-03-1 . ] [ run-03-2 . ] bi ;


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

: read-04 ( -- cards ) "04.txt" read-input ;
: run-04-1 ( cards -- n ) [ card-value ] map-sum ;
: run-04-2 ( cards -- n ) [ 1s ] [ [ card-matches ] map ] bi over [ stepstate ] reduce drop sum ;
: run-04 ( -- ) read-04 [ run-04-1 . ] [ run-04-2 . ] bi ;

! Day 5

: read-05 ( -- strings ) "05.txt" read-input ;

: lengthed-range ( start length -- range ) over + [a..b) ;
: while-nonempty ( .. seq quot: ( .. seq -- .. seq ) -- .. seq ) [ dup empty? not ] swap while ; inline
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

: run-05 ( -- ) read-05 [ run-05-1 . ] [ run-05-2 . ] bi ;


! Day 6

: read-06 ( -- strings ) "06.txt" read-input ;
: parse-06 ( strings -- times distances ) [ split-words-multspace rest [ string>number ] map ] map first2 ;
: parse-06-single ( strings -- time distance ) [ split-words-multspace rest concat string>number ] map first2 ;
: inv-parts ( time distance -- centre radius ) [ 2 / dup sq ] dip - sqrt ;
: open-members ( centre radius -- n ) [ + 1 - ceiling >fixnum 1 + ] [ - 1 + floor >fixnum ] 2bi [-] ;
: button-times ( time distance -- n ) inv-parts open-members ;
: run-06-1 ( strings -- n ) parse-06 [ button-times ] [ * ] 2map-reduce ;
: run-06-2 ( strings -- n ) parse-06-single button-times ;
: run-06 ( -- ) read-06 [ run-06-1 . ] [ run-06-2 . ] bi ;


! Day 7

: read-07 ( -- strings ) "07.txt" read-input ;
: parse-07 ( strings -- pairs ) [ split-words first2 [ [ 1string ] { } map-as ] dip string>number 2array ] map ;
: type2 ( hist -- type ) values 4 swap member? 6 5 ? ;
: type3 ( hist -- type ) values 3 swap member? 4 3 ? ;
: hist-type ( hist -- type ) dup >alist length { { 1 [ drop 7 ] } { 2 [ type2 ] } { 3 [ type3 ] } { 4 [ drop 2 ] } { 5 [ drop 1 ] } } case ;
: picture-value ( card -- n ) { { CHAR: A [ 14 ] } { CHAR: T [ 10 ] } { CHAR: J [ 11 ] } { CHAR: Q [ 12 ] } { CHAR: K [ 13 ] } } case ;
: card-rank ( card -- n ) dup digit? [ 1string string>number ] [ picture-value ] if ;
: ranks ( hand -- ns ) concat [ card-rank ] { } map-as ;
: pair-value ( pair n -- n ) [ second ] dip 1 + * ;
: partition-by ( seq quot: ( elt -- key ) -- seqs ) [ sort-by ] keep group-by ; inline
: hand-type ( pair prep: ( hand -- hand ) -- type ) [ first histogram ] dip call hist-type ; inline
: hand-ranks ( pair prep: ( card -- card ) -- ns ) [ first ] dip map ranks ; inline
: sort-by-hand ( pairs hand-prep: ( hand-hist -- hand-alist ) card-prep: ( card -- card ) -- pairs ) [ [ hand-type ] curry partition-by ] dip [ [ hand-ranks ] curry [ sort-by ] curry [ second ] swap compose call( pair -- pairs ) ] curry map concat ; inline

: best-card ( hist -- card ) >alist dup values supremum [ [ second ] dip = ] curry filter keys [ first card-rank ] supremum-by ;
: add-free ( hist n -- alist ) [ dup best-card 2dup swap at ] dip + set-of ;
: free-hand ( n -- alist ) "A" swap 2array 1array ;
: best-hand ( hist n-free -- alist ) [ >alist ] dip over length 0 > [ add-free ] [ nip free-hand ] if ;
: Js-to-best ( hist -- alist ) "J" over delete-at* [ best-hand ] [ drop ] if ;
: J-to-0 ( card -- card ) dup "J" = [ drop "0" ] when ;

: run-07-1 ( strings -- n ) parse-07 [ ] [ ] sort-by-hand [ pair-value ] map-index sum ;
: run-07-2 ( strings -- n ) parse-07 [ Js-to-best ] [ J-to-0 ] sort-by-hand [ pair-value ] map-index sum ;
: run-07 ( -- ) read-07 [ run-07-1 . ] [ run-07-2 . ] bi ;


! Day 8

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
:: check-gcd-opp-spec ( x y -- ? ) [ swap ] [ gcd ] bi [ * ] dip - swap mod 0 = ;
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

: read-08 ( -- strings ) "08.txt" read-input ;
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
: path-arr ( path -- flat-path ) dup leadin-time [ f pad-tail [ 1array ] map ] curry map unclip [ [ append ] 2map ] reduce concat sift ;
: with-indices ( seq -- seq ) [ 2array ] { } map-index-as ;
: same-last ( cycle -- 1indexes ) [ with-indices ] [ last [ [ first ] dip = ] curry ] bi filter [ second 1 + ] map ;
: possible-groups ( cycle -- group-sets ) dup same-last dup last [ swap / ] curry map [ integer? ] filter over length [ swap / ] curry map swap [ swap <groups> ] curry map ;
: shorten-cycle ( cycle -- cycle ) possible-groups [ dup first [ = ] curry all? ] filter first first >array ;
: clean-path ( path start-loop ndir end-index -- clean-path ) [ path-arr ] 3dip cycle-start [ head ] [ tail shorten-cycle ] 2bi 2array ;
: move-until-cycle ( path network directions -- clean-path ) 0 f [ dup ] [ drop move-08 ] until [ nip length ] 2dip -rot clean-path ;

: ends-with? ( seq x -- ? ) [ last ] dip = ;
: starts ( map -- seq ) keys [ CHAR: A ends-with? ] filter ;
:: paths ( directions network -- paths ) network starts [ 1array 0 directions length <path-buckets> [ set-nth ] keep ] map ;
: split-cycle ( n path -- path1 path2 ) tuck second length rem 1array [ second ] dip split-indices first2 ;
: nrot-seq ( n path -- path' ) tuck split-cycle over append [ [ first ] dip append ] dip 2array ;
: collapse-to-common-start ( paths -- leadin-time paths' ) [ [ leadin-time ] map [ supremum ] [ ] [ supremum ] tri [ swap - ] curry map ] keep [ nrot-seq ] 2map ;
: indices-where ( seq quot: ( el -- ? ) -- ns ) [ with-indices ] dip [ first ] prepose filter seconds ; inline
: end-loc? ( string -- ? ) CHAR: Z ends-with? ;
: end-indices ( seq -- ns ) [ end-loc? ] indices-where ;
: check-early-end ( paths -- cycles n/? ) [ seconds ] [ firsts ] bi [ end-indices ] map unclip [ union ] reduce dup empty? [ drop f ] [ first ] if ;
: end-cong ( cycle -- mod-vals-pair ) [ length ] [ end-indices ] bi 2array ;
: solve-cycles ( cycles -- n ) [ end-cong ] map unclip [ combine-congruences ] reduce second dup empty? [ ] when infimum ;

: run-08-2 ( strings -- n )
  parse-08
  2dup paths
  -rot swap [ move-until-cycle ] curry curry map
  collapse-to-common-start check-early-end dup [ nip ] [ drop solve-cycles ] if + ;
: run-08 ( -- ) read-08 [ run-08-1 . ] [ run-08-2 . ] bi ;


! Day 9

: read-09 ( -- seqs ) "09.txt" read-input [ parse-nums ] map ;
: all-equal? ( seq -- ? ) [ first ] keep swap [ = ] curry all? ;
: outer-nums ( seq -- pair ) dup all-equal? [ first dup 2array ] [ [ [ first ] [ last ] bi 2array ] [ 2 <clumps> [ first2 swap - ] map outer-nums { -1 1 } v* ] bi v+ ] if ;
: process-09 ( seqs -- pair ) [ outer-nums ] [ v+ ] map-reduce ;
: run-09-1 ( pair -- n ) second ;
: run-09-2 ( pair -- n ) first ;
: run-09 ( -- ) read-09 process-09 [ run-09-1 . ] [ run-09-2 . ] bi ;


! Day 10

: read-10 ( -- strings ) "10.txt" read-input ;
: positions ( strings -- poss ) [ length [0..b) ] [ first length [0..b) ] bi [ swap 2array ] cartesian-map concat ;
: parse-10 ( strings -- map ) [ positions ] [ concat ] bi [ 2array ] 2map >hashtable ;
: find-start ( map -- pos )  [ keys ] [ values ] bi CHAR: S [ = ] curry find drop swap nth ;
: valid-pos? ( map pos -- ? ) swap key? ;
: mpipe ( map pos -- pipe/f ) swap at ;
: compass-directions ( -- seq ) { { 0 -1 } { 1 0 } { 0 1 } { -1 0 } } ;
: mneighbours ( pos -- dir-pos-pairs ) compass-directions [ [ v+ ] keep swap 2array ] with map ;
: in-map ( map dir-pos-pairs -- dir-pos-val-triples ) swap [ dupd [ second ] dip ?at [ suffix ] [ 2drop f ] if ] curry map sift ;
: up ( -- pair ) { 0 -1 } ; inline
: down ( -- pair ) { 0 1 } ; inline
: left ( -- pair ) { -1 0 } ; inline
: right ( -- pair ) { 1 0 } ; inline
: opposing? ( pair pair' -- ? ) v+ [ 0 = ] all? ;
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
: connects-in? ( dir-pos-val -- ? ) first3 nip facings dup [ swap [ opposing? ] curry any? ] [ 2drop f ] if ;
: valid-neighbours ( map pos -- dir-pos-val-s ) mneighbours in-map [ connects-in? ] filter ;
: find-start-connections ( start map -- dir-pos-val-s ) swap valid-neighbours ;
: next-dir-in-loop ( dir-pos-val -- dir' ) first3 nip facings swap [ opposing? ] curry reject first ;
: next-in-loop ( hist dir-pos-val map -- hist' dir'-pos'-val'/f map )
  [ [ second ] keep ] dip ! ( hist pos dir-pos-val map )
  [ [ 2dup swap member? [ drop f ] [ suffix t ] if ] keep ] 2dip ! ( hist' ? pos dir-pos-val map )
  [ rot ] dip swap ! ( hist' pos dir-pos-val map ? )
    [
      [ next-dir-in-loop ] dip ! ( hist pos dir' map )
      [ [ v+ ] keep ] dip ! ( hist pos' dir' map ) ;
      [ swap [ 2array ] keep ] dip ! ( hist dir'-pos' pos' map )
      [ at suffix ] keep ! ( hist dir'-pos'-val' map )
    ]
    [ [ 2drop f ] dip ] ! ( hist' f map )
  if ;
: find-loop ( start-connections start-pos map -- loop ) swapd [ 1array ] 2dip [ over ] [ next-in-loop ] while 2drop ;
: run-10-1 ( strings -- n ) parse-10 [ find-start ] keep dupd [ find-start-connections ] keep swapd [ find-loop ] curry curry map [ ] find nip length 2 / ;
