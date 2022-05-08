# Pseudocode

This file provides the pseudocode to simplify implementations of EDGE in any programming language. 

### Input

`O`, `H`, `L`, `C` vectors of Open, High, Low, and Close prices. The vectors must be ordered in ascending order of the timestamp.

### Output

Numeric spread estimate.

### Algorithm

2. Convert the `O`, `H`, `L`, `C` vectors to logs: `o = log(O)`, `h = log(H)`,  `l = log(L)`, `c = log(C)`
3. Compute the mid prices: `m = (h+l)/2`
4. Lag the vectors of one period: `c1 = lag(c)`, `m1 = lag(m)`, `h1 = lag(h)`, `l1 = lag(l)`
5. Compute the vector `x1 = (m-o)*(o-m1)+(m-c1)*(c1-m1)`
6. Compute the vector `x2 = (m-o)*(o-c1)+(o-c1)*(c1-m1)`
7. Compute the means `e1 = mean(x1)` and `e2 = mean(x2)`
8. Compute the variances `v1 = var(x1)` and `v2 = var(x2)`
9. Compute the weights `w1 = v2/(v1+v2)` and `w2 = v1/(v1+v2)`
9. Compute `k = 4*w1*w2`
10. Compute the fraction of times, for t = 2, ..., T, in which:
    1. the open equals the high `n1 = mean(o==h)`
    2. the open equals the low `n2 = mean(o==l)`
    3. the previous close equals the previous high `n3 = mean(c1==h1)`
    4. the previous close equals the previous low `n4 = mean(c1==l1)`
    5. the high price equals the low price and the previous close: `n5 = mean(h==l & l==c1)`
11. Compute the squared spread `s2 = -4*(w1*e1+w2*e2)/((1-k*(n1+n2)/2)+(1-n5)*(1-k*(n3+n4)/2))`
12. Return the spread `s = sqrt(max(0, s2))`

### Testing

To check the implementation is correct, import the data available at:

- https://raw.githubusercontent.com/eguidotti/bidask/main/data/ohlc.csv

Then, run the estimation. You should obtain a spread estimate of **0.0100504050543988**. If you obtain a different results, you may use the following table to check and debug the intermediate steps.

| variable | value                  |
| -------- | ---------------------- |
| `e1`     | -3.260522974964389e-05 |
| `e2`     | -3.097026805554595e-05 |
| `v1`     | 1.9196668557136508e-07 |
| `v2`     | 1.2454024931191764e-07 |
| `w1`     | 0.3934834772509613     |
| `w2`     | 0.6065165227490388     |
| `n1`     | 0.38153815381538153    |
| `n2`     | 0.39053905390539057    |
| `n3`     | 0.38453845384538454    |
| `n4`     | 0.387038703870387      |
| `n5`     | 0.017901790179017902   |
| `s2`     | 0.00010101064175748407 |

### Contribute

Have you implemented EDGE in a new programming language? If you want your implementation to be included in this repository, please open a [pull request](https://github.com/eguidotti/bidask/pulls) 