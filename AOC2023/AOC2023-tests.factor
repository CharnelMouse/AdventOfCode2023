USING: tools.test AOC2023 kernel arrays sequences ;
IN: AOC2023.tests

: int-test ( quot: ( -- n ) n -- ) 1array swap unit-test ;
: task-out ( quot: ( data -- n ) n -- quot: ( data -- ) ) [ [ curry ] curry ] dip [ int-test ] curry append ; inline
: int-bitest ( data quot: ( data -- n ) n quot: ( data -- n ) n -- ) [ task-out ] 2bi@ bi ; inline
: int-tritest ( data quot: ( data -- n ) n quot: ( data -- n ) n quot: ( data -- n ) n -- ) [ [ task-out ] 2bi@ ] 2dip task-out tri ; inline

[
{
"1abc2"
"pqr3stu8vwx"
"a1b2c3d4e5f"
"treb7uchet"
}
run-01-1
]
142
int-test

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
run-01-2
]
281
int-test

{
"Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green"
"Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue"
"Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red"
"Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red"
"Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"
}
[ run-02-1 ] 8
[ run-02-2 ] 2286
int-bitest

{
"467..114.."
"...*......"
"..35..633."
"......#..."
"617*......"
".....+.58."
"..592....."
"......755."
"...$.*...."
".664.598.."
}
[ run-03-1 ] 4361
[ run-03-2 ] 467835
int-bitest

{
"Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53"
"Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19"
"Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1"
"Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83"
"Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36"
"Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11"
}
[ run-04-1 ] 13
[ run-04-2 ] 30
int-bitest

{
"seeds: 79 14 55 13"
""
"seed-to-soil map:"
"50 98 2"
"52 50 48"
""
"soil-to-fertilizer map:"
"0 15 37"
"37 52 2"
"39 0 15"
""
"fertilizer-to-water map:"
"49 53 8"
"0 11 42"
"42 0 7"
"57 7 4"
""
"water-to-light map:"
"88 18 7"
"18 25 70"
""
"light-to-temperature map:"
"45 77 23"
"81 45 19"
"68 64 13"
""
"temperature-to-humidity map:"
"0 69 1"
"1 0 69"
""
"humidity-to-location map:"
"60 56 37"
"56 93 4"
}
[ run-05-1 ] 35
[ run-05-2 ] 46
int-bitest

{
"Time:      7  15   30"
"Distance:  9  40  200"
}
[ run-06-1 ] 288
[ run-06-2 ] 71503
int-bitest

{
"32T3K 765"
"T55J5 684"
"KK677 28"
"KTJJT 220"
"QQQJA 483"
}
[ run-07-1 ] 6440
[ run-07-2 ] 5905
int-bitest

[
{
"JJJJJ 1"
"AAAAK 2"
"TTTTT 3"
}
run-07-2
]
13
int-test

{
"RL"
""
"AAA = (BBB, CCC)"
"BBB = (DDD, EEE)"
"CCC = (ZZZ, GGG)"
"DDD = (DDD, DDD)"
"EEE = (EEE, EEE)"
"GGG = (GGG, GGG)"
"ZZZ = (ZZZ, ZZZ)"
}
[ run-08-1 ] 2
[ run-08-2 ] 2
int-bitest

{
"LLR"
""
"AAA = (BBB, BBB)"
"BBB = (AAA, ZZZ)"
"ZZZ = (ZZZ, ZZZ)"
}
[ run-08-1 ] 6
[ run-08-2 ] 6
int-bitest

[
{
"LR"
""
"11A = (11B, XXX)"
"11B = (XXX, 11Z)"
"11Z = (11B, XXX)"
"22A = (22B, XXX)"
"22B = (22C, 22C)"
"22C = (22Z, 22Z)"
"22Z = (22B, 22B)"
"XXX = (XXX, XXX)"
}
run-08-2
]
6
int-test

{
{ 0 3 6 9 12 15 }
{ 1 3 6 10 15 21 }
{ 10 13 16 21 30 45 }
}
[ process-09 run-09-1 ] 114
[ process-09 run-09-2 ] 2
int-bitest

[
{
"....."
".S-7."
".|.|."
".L-J."
"....."
}
prepare-10
run-10-1
]
4
int-test

[
{
"..F7."
".FJ|."
"SJ.L7"
"|F--J"
"LJ..."
}
prepare-10
run-10-1
]
8
int-test

[
{
"..........."
".S-------7."
".|F-----7|."
".||.....||."
".||.....||."
".|L-7.F-J|."
".|..|.|..|."
".L--J.L--J."
"..........."
}
prepare-10
run-10-2
]
4
int-test

[
{
".F----7F7F7F7F-7...."
".|F--7||||||||FJ...."
".||.FJ||||||||L7...."
"FJL7L7LJLJ||LJ.L-7.."
"L--J.L7...LJS7F-7L7."
"....F-J..F7FJ|L7L7L7"
"....L7.F7||L7|.L7L7|"
".....|FJLJ|FJ|F7|.LJ"
"....FJL-7.||.||||..."
"....L---J.LJ.LJLJ..."
}
prepare-10
run-10-2
]
8
int-test

[
{
"FF7FSF7F7F7F7F7F---7"
"L|LJ||||||||||||F--J"
"FL-7LJLJ||||||LJL-77"
"F--JF--7||LJLJ7F7FJ-"
"L---JF-JLJ.||-FJLJJ7"
"|F|F-JF---7F7-L7L|7|"
"|FFJF7L7F-JF7|JL---7"
"7-L-JL7||F7|L7F-7F7|"
"L.L7LFJ|||||FJL7||LJ"
"L7JLJL-JLJLJL--JLJ.L"
}
prepare-10
run-10-2
]
10
int-test

{
"...#......"
".......#.."
"#........."
".........."
"......#..."
".#........"
".........#"
".........."
".......#.."
"#...#....."
}
[ process-11 run-11-1 ] 374
[ process-11 10 run-11-n ] 1030
[ process-11 100 run-11-n ] 8410
int-tritest

[
{
"???.### 1,1,3"
".??..??...?##. 1,1,3"
"?#?#?#?#?#?#?#? 1,3,1,6"
"????.#...#... 4,1,1"
"????.######..#####. 1,6,5"
"?###???????? 3,2,1"
}
run-12-1
]
21
int-test
