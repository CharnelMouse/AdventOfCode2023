USING: io.encodings.utf8 io.files io unicode sequences strings kernel math.parser ranges quotations arrays combinators regexp math prettyprint accessors splitting math.order sets grouping math.functions ;
IN: AOC2023

! Common words

: read-input ( path -- seq ) utf8 [ read-lines ] with-file-reader ;
: as-seq ( x -- seq ) 1array ;
: replace-nth ( new n seq -- seq' ) [ 1array ] 2dip [ dup 1 + ] dip replace-slice ;


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
: cardhalves ( string -- pair ) "|" split [ split-words harvest ] map ;
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

: cut-paragraph ( strings -- paragraph rest-strings ) { "" } split1 ;
: lengthed-range ( start length -- range ) over + [a..b) ;
: while-nonempty ( .. seq quot: ( .. seq -- .. seq ) -- .. seq ) [ dup empty? not ] swap while ; inline
: empty-range ( -- range ) T{ range { step 1 } } ;
: parse-perm ( string -- seq ) split-words [ string>number ] map ;
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
: bind-range-n ( seq<n-?> perm-string -- seq<n-?> ) parse-perm [ apply-perm-if-clean-n ] curry map ;
: apply-map-n ( ns map -- ns ) rest swap [ clean ] map [ bind-range-n ] reduce [ remove-flag ] map ;
: next-map-n ( ns maps -- ns rest-maps ) cut-paragraph [ apply-map-n ] dip ;
: run-05-1 ( strings -- n ) cut-seeds [ next-map-n ] while-nonempty drop infimum ;

: ap-r ( range perm -- seq<range-?> ) [ split-by-perm ] keep inc-middle-range c-d-c reject-empty ;
: apply-perm-r ( r-f perm -- seq<r-?> ) [ remove-flag ] dip ap-r ;
: apply-perm-if-clean-r ( r-? perm -- seq<r-?> ) [ apply-perm-r ] curry [ as-seq ] if-clean ;
: bind-range-r ( seq<r-?> perm-string -- seq<r-?> ) parse-perm [ apply-perm-if-clean-r ] curry map concat ;
: apply-map-r ( rs map -- rs ) rest swap [ clean ] map [ bind-range-r ] reduce [ remove-flag ] map ;
: next-map-r ( rs maps -- rs rest-maps ) cut-paragraph [ apply-map-r ] dip ;
: run-05-2 ( strings -- n ) cut-seed-ranges [ next-map-r ] while-nonempty drop [ first ] map infimum ;

: run-05 ( -- ) read-05 [ run-05-1 . ] [ run-05-2 . ] bi ;


! Day 6
! Pressing button for time t out of T gives distance d = t(T-t),
! so time to attain distance d is t = T/2 +- sqrt(T^2/4 - d).

: read-06 ( -- strings ) "06.txt" read-input ;
: parse-06 ( strings -- times distances ) [ split-words harvest rest [ string>number ] map ] map first2 ;
: button-times ( time distance -- n ) [ 2 / dup sq ] dip - sqrt [ + 1 - ceiling >fixnum 1 + ] [ - 1 + floor >fixnum ] 2bi [-] ;
: run-06-1 ( strings -- n ) parse-06 [ button-times ] [ * ] 2map-reduce ;
