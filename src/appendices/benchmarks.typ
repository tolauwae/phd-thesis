== Microbenchmarks<remote:microbenchmarks>

Our microbenchmarks are implemented as described below.

/ tak: a popular function from the Gabriel Benchmarks, contains an implementation of Takeuchi's tak function, specifically $tau(18,12,6)$.
/ catalan: computes various Catalan numbers. The $n$-th Catalan number is commuted with: $C_n = frac(1, n+1)binom(2n, n)$. The benchmark implements this formula up to the 17th Catalan number (to avoid overflow).
/ fac: implements a recursive implementation for calculating the integer factorial function. In the benchmark we calculate $(n mod 12)!$ for $n in bracket.l 0, 1000 bracket.l$.
/ fib: determines the value of the $n$#super[th] Fibonacci number iteratively, for all $n in bracket.l 1000, 1050 bracket.l$.
/ gcd: computes the greatest common denominator of two numbers. In the benchmark we calculate the gcd of all whole numbers in $bracket.l 4000, 5000 bracket.l$ and 12454.
/ primes: verifies if numbers are prime by looking for divisors. The benchmark consists of finding and calculating the sum of the first 127 primes.

