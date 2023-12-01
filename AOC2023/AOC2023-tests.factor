! Copyright (C) 2023 Your name.
! See https://factorcode.org/license.txt for BSD license.
USING: tools.test AOC2023 ;
IN: AOC2023.tests

{ { 12 38 15 77 } }
[
{
"1abc2"
"pqr3stu8vwx"
"a1b2c3d4e5f"
"treb7uchet"
}
to-nums
]
unit-test

{ { 29 83 13 24 42 14 76 } }
[
{
"two1nine"
"eightwothree"
"abcone2threexyz"
"xtwone3four"
"4nineeightseven2"
"zoneight234"
"7pqrstsixteen"
}
to-nums2
]
unit-test
