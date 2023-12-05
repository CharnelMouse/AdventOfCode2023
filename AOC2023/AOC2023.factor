USING: io.encodings.utf8 io.files io unicode sequences strings kernel math.parser ranges quotations arrays combinators regexp math prettyprint accessors splitting math.order sets assocs grouping sequences.private ;
IN: AOC2023

: read-input ( path -- seq ) utf8 [ read-lines ] with-file-reader ;


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

: replace-nth ( new n seq -- seq' ) [ dup 1 + ] dip replace-slice ;
: max-nth ( seq new n -- seq' ) [ 2dup nth ] dip max { 0 } 1sequence -rot replace-nth ;
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

: as-seq ( x -- seq ) { } 1sequence ;

: period? ( char -- ? ) CHAR: . = ;
: nonpersymb? ( char -- ? ) [ digit? ] [ period? ] bi or not ;
: gear? ( char -- ? ) CHAR: * = ;

: tst ( seq x -- 1seq ) as-seq [ last ] dip append as-seq ;
: add-to-last ( seq x -- seq' ) [ tst ] curry [ length 1 - ] [ ] tri replace-nth ;
: new-subseq ( seq -- seq' ) { { } } append ;
: split-on-false ( seq n/f -- seq )  dup [ add-to-last ] [ drop new-subseq ] if ;
: group-nonfalse ( seq -- subseqs ) { { } } [ split-on-false ] reduce harvest ;
: digit/f ( char n -- char/f ) swap digit? [ ] [ drop f ] if ;
: digit-slices ( string -- index-slices ) [ digit/f ] { } map-index-as group-nonfalse ;

: index/f ( x y quot: ( x -- ? ) --  ) dip swap [ ] [ drop f ] if ; inline
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

: parse-seeds ( string -- seeds ) first split-words rest [ string>number ] map ;
: take-seeds ( strings -- seeds strings ) { "" } split1 [ parse-seeds ] dip ;
: within-source ( n range-string -- ? ) [ second - ] [ third nip ] 2bi [ drop 0 >= ] [ < ] 2bi and ;
: <pair> ( x y -- seq ) { } 2sequence ;
: apply-range ( n-f range-string -- n-t ) [ first ] dip split-words [ string>number ] map 2dup within-source [ tuck second - [ first ] dip + t <pair> ] [ drop f <pair> ] if ;
: bind-range ( n-? range-string -- n-? ) over second [ drop ] [ apply-range ] if ;
: apply-map ( n map-strings -- n ) rest swap f <pair> [ bind-range ] reduce first ;
: next-map ( ns strings -- ns rest-strings ) { "" } split1 [ [ apply-map ] curry map ] dip ;
: run-05-1 ( strings -- n ) take-seeds [ dup empty? not ] [ next-map ] while drop infimum ;

: parse-seed-ranges ( string -- seed-ranges ) parse-seeds 2 group [ [ first ] [ second ] bi over + [a..b) ] map ;
: take-seed-ranges ( strings -- seed-ranges strings ) { "" } split1 [ parse-seed-ranges ] dip ;
: all-before? ( range indices -- ? ) [ last ] dip first < ;
: any-before? ( range indices -- ? ) [ first ] dip first < ;
: all-after? ( range indices -- ? ) [ first ] dip last > ;
: any-after? ( range indices -- ? ) [ last ] dip last > ;
: empty-range ( -- range ) T{ range { step 1 } } ;
: range-before ( range indices -- range ) 2dup any-before? [ [ drop first ] [ [ last ] dip first 1 - min ] 2bi [a..b] ] [ 2drop empty-range ] if ;
: range-within ( range indices -- range ) 2dup [ all-before? ] [ all-after? ] 2bi or [ 2drop empty-range ] [ [ [ first ] bi@ max ] [ [ last ] bi@ min ] 2bi [a..b] ] if ;
: range-after ( range indices -- range ) 2dup any-after? [ [ [ first ] dip last 1 + max ] [ drop last ] 2bi [a..b] ] [ 2drop empty-range ] if ;
: split-indices-range ( range indices -- piece-ranges ) [ range-before ] [ range-within ] [ range-after ] 2tri { } 3sequence ;
: split-indices-bound ( seq indices -- pieces ) split-indices-range ;
: parse-source-range ( map-range -- source-range ) [ second ] [ third ] bi over + [a..b) ;
: split-range-intersect ( range range-string -- 3ranges ) parse-source-range split-indices-bound ;
: +range ( range n -- range ) [ [ from>> ] dip + ] [ drop length>> ] 2bi over + [a..b) ;
: apply-range-ranged ( range-f range-string -- seq<range-t> ) [ first ] dip split-words [ string>number ] map tuck split-range-intersect swap [ first ] [ second ] bi - over second swap +range as-seq swap 1 swap replace-nth { f t f } [ <pair> ] 2map [ first empty? not ] filter ;
: bind-range-ranged ( seq<range-?> range-string -- seq<range-?> ) dup split-words third "0" = [ drop ] [ [ over second [ drop as-seq ] [ apply-range-ranged ] if ] curry map concat ] if ;
: apply-map-ranged ( range map-strings -- ranges ) rest swap f <pair> as-seq [ bind-range-ranged ] reduce [ first ] map ;
: next-map-ranged ( ranges strings -- ranges rest-strings ) { "" } split1 [ [ apply-map-ranged ] curry map concat ] dip ;
: run-05-2 ( strings -- n ) take-seed-ranges [ dup empty? not ] [ next-map-ranged ] while drop [ first ] map infimum ;
: run-05-2-debug ( strings -- ) take-seed-ranges over . [ dup empty? not ] [ dup { "" } split1 drop . next-map-ranged "=>" print over . ] while drop [ first ] map dup . infimum . ;
: run-05 ( -- ) read-05 [ run-05-1 . ] [ run-05-2 . ] bi ;
