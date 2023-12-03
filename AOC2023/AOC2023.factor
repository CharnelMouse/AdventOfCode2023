USING: io.encodings.utf8 io.files io unicode sequences strings kernel math.parser ranges quotations arrays combinators regexp math prettyprint accessors splitting math.order classes.tuple sets ;
IN: AOC2023

: read-input ( path -- seq ) utf8 [ read-lines ] with-file-reader ;

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


: replace-nth ( new n seq -- seq' ) [ dup 1 + ] dip replace-slice ;
: max-nth ( seq new n -- seq' ) [ 2dup nth ] dip max { 0 } 1sequence -rot replace-nth ;
: empty-bag ( -- bag ) { 0 0 0 } ;
: bag-power ( bag -- n ) product ;
: colour>n ( string -- n ) { { "red" [ 0 ] } { "green" [ 1 ] } { "blue" [ 2 ] } } case ;
: inc-bag ( bag seq -- bag' ) [ first string>number ] [ second colour>n ] bi -rot max-nth ;
: to-bag ( string -- bag ) "," split [ rest " " split ] map empty-bag [ inc-bag ] reduce ;
: to-bags ( string -- seq ) ":;" split rest [ to-bag ] map ;
: bag-max ( bag bag' -- bag'' ) [ max ] 2map ;
: min-bag ( string -- bag ) to-bags empty-bag [ bag-max ] reduce ;
: valid ( string bag -- ? ) [ min-bag ] dip [ <= ] 2all? ;
: n-if-valid ( string n bag -- n ) swapd valid [ 1 + ] [ drop 0 ] if ;

: read-02 ( -- seq ) "02.txt" read-input ;
: run-02-1 ( seq -- n ) [ { 12 13 14 } n-if-valid ] map-index 0 [ + ] reduce ;
: run-02-2 ( seq -- f ) [ min-bag bag-power ] map-sum ;
: run-02 ( -- ) read-02 [ run-02-1 . ] [ run-02-2 . ] bi ;


TUPLE: pos { x integer read-only } { y integer read-only } ; 
C: <pos> pos

: period? ( char -- ? ) CHAR: . = ;
: nonpersymb? ( char -- ? ) [ digit? ] [ period? ] bi or not ;
: true-index ( seq quot: ( x -- ? ) -- seq ) [ dip swap [ ] [ drop f ] if ] curry { 0 } map-index-as ; inline
: slice-true ( seq quot: ( x -- ? ) -- seq ) true-index [ number? ] filter ; inline
: split-on-false ( seq n/f -- seq )  dup [ { } 1sequence dupd [ last ] dip append { } 1sequence swap dup [ length 1 - ] dip replace-nth ] [ drop { { } } append ] if ;
: group-nonfalse ( seq -- seq<seq> ) { { } } [ split-on-false ] reduce ;
: digit-slices ( seq<a> -- seq<seq<a>> ) [ swap digit? [ ] [ drop f ] if ] { } map-index-as group-nonfalse ;
: nonpersymb-indices ( seq<a> -- seq<a> ) [ nonpersymb? ] slice-true ;
: get-pos ( row n quot: ( seq -- seq ) -- seq ) dip [ <pos> ] curry map ; inline
: get-pos-set ( row n quot: ( seq -- seq ) -- seq ) dip [ <pos> ] curry [ map ] curry map ; inline
: num-pos ( row n -- seq<seq<pos>> ) [ digit-slices ] get-pos-set harvest ;
: sym-pos ( row n -- seq<pos> ) [ nonpersymb-indices ] get-pos ;
: number-position-sets ( seq<string> -- seq<seq<pos>> ) [ num-pos ] map-index concat ;
: symbol-positions ( seq<string> -- set<pos> ) [ sym-pos ] map-index concat ;

: replace-row ( rowmatches quot: ( n -- n ) -- rowmatches ) dupd [ row>> ] dip call >>row ; inline
: pleft ( set<pos> -- set<pos> ) [ [ x>> 1 - ] [ y>> ] bi <pos> ] map ;
: pright ( set<pos> -- set<pos> ) [ [ x>> 1 + ] [ y>> ] bi <pos> ] map ;
: pup ( set<pos> -- set<pos> ) [ [ x>> ] [ y>> 1 - ] bi <pos> ] map ;
: pdown ( set<pos> -- set<pos> ) [ [ x>> ] [ y>> 1 + ] bi <pos> ] map ;
: paside ( set<pos> -- set<pos> ) [ pleft ] [ pright ] bi union ;
: pexpand ( set<pos> -- set<pos> ) [ ] [ pleft ] [ pright ] tri union union ;
: pabove ( set<pos> -- set<pos> ) pup pexpand ;
: pbelow ( set<pos> -- set<pos> ) pdown pexpand ;
: neighbours ( set<pos> -- set<pos> ) [ paside ] [ pabove ] [ pbelow ] tri union union ;

: adjacent-single ( seq<pos> -- quot: ( seq<pos> -- ? ) ) [ intersect empty? not ] curry [ filter ] curry  ; inline
: adjacent ( seq<seq<pos>> seq<pos> -- seq<seq<pos>> ) adjacent-single call ;
: num ( set<pos> seq<string> -- int ) over first y>> swap nth [ [ first x>> ] [ last x>> 1 + ] bi ] dip subseq string>number ;

: read-03 ( -- seq<string> ) "03.txt" read-input ;
: run-03-1 ( seq<string> -- n ) [ [ number-position-sets ] [ symbol-positions neighbours ] bi adjacent ] [ ] bi [ num ] curry map-sum ;
: run-03 ( -- ) read-03 run-03-1 . ;
