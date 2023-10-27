# Hello Compute

Runs a compute shader to determine the number of iterations of the rules from
Collatz Conjecture

- If n is even, n = n/2
- If n is odd, n = 3n+1

that it will take to finish and reach the number `1`.

Output:

```shell
Steps: [0, 1, 7, 2]
```

## Build

```shell
odin build ./compute -out:./build/<executable-name>
```
