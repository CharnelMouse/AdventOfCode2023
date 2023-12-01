Solutions for problems in Advent of Code 2023: https://adventofcode.com/2023

Goals:

- If using R, everything in base R, i.e. no loading of packages; Possible exception: any day that requires handling numbers too large for base R, e.g. gmp for modular arithmetic with integers too large for base R's %/% and %%. No regex.
- If using Factor, everything goes, because I haven't used it before.

To get this working in Factor, where [path] is the folder, write the following to set the AOC2023 folder as a Factor library:

```factor
USE: tools.scaffold
[path] set-current-directory
[path] add-vocab-root
[path] "AOC2023" scaffold-vocab-in
USE: AOC2023
```
