! Copyright (C) 2023 Your name.
! See https://factorcode.org/license.txt for BSD license.
USING: io.encodings.utf8 io.files io unicode sequences kernel math.parser strings math prettyprint regexp combinators arrays quotations accessors ranges ;
IN: AOC2023

: read-01 ( -- seq ) "01.txt" utf8 [ read-lines ] with-file-reader ;
: digits ( string -- string ) [ digit? ] filter ;
: ends ( string -- n ) [ first 1string ] [ last 1string ] bi append string>number ;
: to-num ( string -- n ) digits ends ;
: to-nums ( seq -- seq ) [ to-num ] map ;
: run-01-1 ( seq -- n ) to-nums 0 [ + ] reduce ;
: digit-names ( -- seq ) { "zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine" } ;
: digits-seq ( -- seq ) 0 9 [a..b] ;
: replace-args ( -- seq ) digit-names [ <regexp> ] map digits-seq [ 2array ] 2map ;
: replace-quots ( -- seq ) replace-args [ >quotation [ re-replace ] append ] map ;
: apply-all ( seq string -- string ) [ call( string -- string ) ] reduce ;
: string-to-num ( string -- n ) { { "zero" [ 0 ] } { "one" [ 1 ] } { "two" [ 2 ] } { "three" [ 3 ] } { "four" [ 4 ] } { "five" [ 5 ] } { "six" [ 6 ] } { "seven" [ 7 ] } { "eight" [ 8 ] } { "nine" [ 9 ] } [ string>number ] } case ;
: to-regexp ( seq -- regexp ) "\\d" [ "|" swap append append ] reduce <regexp> ;
: find-first ( string seq -- string ) to-regexp first-match >string ;
: find-last ( string seq -- string ) [ reverse ] dip [ reverse ] map find-first reverse ;
: to-num2 ( string -- n ) digit-names [ find-first string-to-num 10 * ] [ find-last string-to-num ] 2bi + ;
: to-nums2 ( seq -- seq ) [ to-num2 ] map ;
: run-01-2 ( seq -- n ) to-nums2 0 [ + ] reduce ;
: run-01 ( -- ) read-01 [ run-01-1 . ] [ run-01-2 . ] bi ;
