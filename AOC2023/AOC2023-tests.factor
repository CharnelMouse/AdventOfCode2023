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

{
"???.### 1,1,3"
".??..??...?##. 1,1,3"
"?#?#?#?#?#?#?#? 1,3,1,6"
"????.#...#... 4,1,1"
"????.######..#####. 1,6,5"
"?###???????? 3,2,1"
}
[ run-12-1 ] 21
[ run-12-2 ] 525152
int-bitest

{
"#.##..##."
"..#.##.#."
"##......#"
"##......#"
"..#.##.#."
"..##..##."
"#.#.##.#."
""
"#...##..#"
"#....#..#"
"..##..###"
"#####.##."
"#####.##."
"..##..###"
"#....#..#"
}
[ run-13-1 ] 405
[ run-13-2 ] 400
int-bitest

{
"O....#...."
"O.OO#....#"
".....##..."
"OO.#O....O"
".O.....O#."
"O.#..O.#.#"
"..O..#O..O"
".......O.."
"#....###.."
"#OO..#...."
}
[ run-14-1 ] 136
[ run-14-2 ] 64
int-bitest

"rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7"
[ run-15-1 ] 1320
[ run-15-2 ] 145
int-bitest

{
".|...\\...."
"|.-.\\....."
".....|-..."
"........|."
".........."
".........\\"
"..../.\\\\.."
".-.-/..|.."
".|....-|.\\"
"..//.|...."
}
[ run-16-1 ] 46
[ run-16-2 ] 51
int-bitest

{
"2413432311323"
"3215453535623"
"3255245654254"
"3446585845452"
"4546657867536"
"1438598798454"
"4457876987766"
"3637877979653"
"4654967986887"
"4564679986453"
"1224686865563"
"2546548887735"
"4322674655533"
}
[ run-17-1 ] 102
[ run-17-2 ] 94
int-bitest

{
"111111111111"
"999999999991"
"999999999991"
"999999999991"
"999999999991"
}
[ run-17-2 ] 71
[ run-17-2 ] 71
int-bitest

{
"R 6 (#70c710)"
"D 5 (#0dc571)"
"L 2 (#5713f0)"
"D 2 (#d2c081)"
"R 2 (#59c680)"
"D 2 (#411b91)"
"L 5 (#8ceee2)"
"U 2 (#caa173)"
"L 1 (#1b58a2)"
"U 2 (#caa171)"
"R 2 (#7807d2)"
"U 3 (#a77fa3)"
"L 2 (#015232)"
"U 2 (#7a21e3)"
}
[ run-18-1 ] 62
[ run-18-2 ] 952408144115
int-bitest

{
"px{a<2006:qkq,m>2090:A,rfg}"
"pv{a>1716:R,A}"
"lnx{m>1548:A,A}"
"rfg{s<537:gd,x>2440:R,A}"
"qs{s>3448:A,lnx}"
"qkq{x<1416:A,crn}"
"crn{x>2662:A,R}"
"in{s<1351:px,qqz}"
"qqz{s>2770:qs,m<1801:hdj,R}"
"gd{a>3333:R,R}"
"hdj{m>838:A,pv}"
""
"{x=787,m=2655,a=1222,s=2876}"
"{x=1679,m=44,a=2067,s=496}"
"{x=2036,m=264,a=79,s=2244}"
"{x=2461,m=1339,a=466,s=291}"
"{x=2127,m=1623,a=2188,s=1013}"
}
[ run-19-1 ] 19114
[ run-19-1 ] 19114
int-bitest

! tests for real inputs, delete if using different ones

1 read-input
[ run-01-1 ] 54940
[ run-01-2 ] 54208
int-bitest

2 read-input
[ run-02-1 ] 2348
[ run-02-2 ] 76008
int-bitest

3 read-input
[ run-03-1 ] 537732
[ run-03-2 ] 84883664
int-bitest

4 read-input
[ run-04-1 ] 21919
[ run-04-2 ] 9881048
int-bitest

5 read-input
[ run-05-1 ] 107430936
[ run-05-2 ] 23738616
int-bitest

6 read-input
[ run-06-1 ] 861300
[ run-06-2 ] 28101347
int-bitest

7 read-input
[ run-07-1 ] 251058093
[ run-07-2 ] 249781879
int-bitest

8 read-input
[ run-08-1 ] 14429
[ run-08-2 ] 10921547990923
int-bitest

9 read-input [ parse-nums ] map process-09
[ run-09-1 ] 1806615041
[ run-09-2 ] 1211
int-bitest

10 read-input prepare-10 dup
[ run-10-1 ] curry 6640 int-test
[ run-10-2 ] curry 411 int-test

11 read-input process-11 2dup
[ run-11-1 ] 2curry 9918828 int-test
[ run-11-2 ] 2curry 692506533832 int-test

12 read-input
[ run-12-1 ] 7344
[ run-12-2 ] 1088006519007
int-bitest

13 read-input
[ run-13-1 ] 31877
[ run-13-2 ] 42996
int-bitest

14 read-input
[ run-14-1 ] 103614
[ run-14-2 ] 83790
int-bitest

15 read-input first
[ run-15-1 ] 511498
[ run-15-2 ] 284674
int-bitest

16 read-input
[ run-16-1 ] 7951
[ run-16-1 ] 7951
! [ run-16-2 ] 6148
int-bitest

! 17 read-input
! [ run-17-1 ] 1099
! [ run-17-2 ] 1266
! int-bitest

18 read-input
[ run-18-1 ] 61661
[ run-18-2 ] 111131796939729
int-bitest

19 read-input
[ run-19-1 ] 383682
[ run-19-1 ] 383682
int-bitest
