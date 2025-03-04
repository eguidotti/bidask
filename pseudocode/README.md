# Pseudocode

This file provides the pseudocode to simplify implementations of the estimator in any programming language. 

### Input

Vectors of `open`, `high`, `low`, and `close` prices. The vectors must be sorted in ascending order of the timestamp. The function should also accept the argument `sign` specifying whether to return signed estimates.

### Output

Numeric spread estimate. A value of 0.01 corresponds to a spread of 1%.

### Algorithm

```python
# check that the open, high, low, and close prices have the same length
nobs = len(open)
if len(high) != nobs or len(low) != nobs or len(close) != nobs:
	raise error

# return missing if there are less than 3 observations
if nobs < 3:
	return missing

# compute log-prices
o = log(open)
h = log(high)
l = log(low)
c = log(close)
m = (h + l) / 2.

# shift log-prices by one period
h1 = lag(h)
l1 = lag(l)
c1 = lag(c)
m1 = lag(m)

# compute log-returns
r1 = m - o
r2 = o - m1
r3 = m - c1
r4 = c1 - m1
r5 = o - c1

# compute indicator variables
tau = (h != l or l != c1) if h, l, c1 are non-missing else missing
po1 = (tau and o != h) if tau, o, h are non-missing else missing
po2 = (tau and o != l) if tau, o, l are non-missing else missing
pc1 = (tau and c1 != h1) if tau, c1, h1 are non-missing else missing
pc2 = (tau and c1 != l1) if tau, c1, l1 are non-missing else missing

# compute probabilities
pt = mean(tau)
po = mean(po1) + mean(po2)
pc = mean(pc1) + mean(pc2)

# return missing if there are less than two periods with tau=1 
# or po or pc is zero
if sum(tau) < 2 or po == 0 or pc == 0:
  return missing

# compute de-meaned log-returns
d1 = r1 - mean(r1)/pt*tau
d3 = r3 - mean(r3)/pt*tau
d5 = r5 - mean(r5)/pt*tau

# compute input vectors
x1 = -4./po*d1*r2 + -4./pc*d3*r4 
x2 = -4./po*d1*r5 + -4./pc*d5*r4 

# compute expectations
e1 = mean(x1)
e2 = mean(x2)

# compute variances
v1 = mean(x1*x1) - e1*e1
v2 = mean(x2*x2) - e2*e2

# compute square spread by using a (equally) weighted 
# average if the total variance is (not) positive
vt = v1 + v2
s2 = (v2*e1 + v1*e2) / vt if vt > 0 else (e1 + e2) / 2.

# compute signed root
s = sqrt(abs(s2))
if sign and s2 < 0: 
    s = -s

# return the spread
return s
```

### Testing

To test your implementation, import the data available [here](https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv). The file contains sample OHLC simulated price data to simplify testing. The data have been generated by simulating a price process as described in [Ardia, Guidotti, & Kroencke (2024)](https://doi.org/10.1016/j.jfineco.2024.103916) with 390 trades per day and a 1% probability to observe a trade. The simulation uses a constant spread of 1%. By running the estimation, you should obtain a spread estimate of **0.0101849034905478**. If you obtain a different result, you may use the following table to check and debug the intermediate steps.

| variable | value                  |
| -------- | ---------------------- |
| `pt`     | 0.9820982098209821     |
| `po`     | 1.227922792279228      |
| `pc`     | 1.2052205220522052     |
| `e1`     | 0.00010702425689560482 |
| `e2`     | 0.000101595812797079   |
| `v1`     | 2.074215642985551e-06  |
| `v2`     | 1.3461279919743572e-06 |
| `s2`     | 0.00010373225911177194 |

To check that your implementation correctly handles missing values, import the data available [here](https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc-miss.csv). The data have been generated by setting to missing a random subset of the previous data file. By running the estimation, you should obtain a spread estimate of **0.01013284969780197**. If you obtain a different result, you may use the following table to check and debug the intermediate steps.

| variable | value                  |
| -------- | ---------------------- |
| `pt`     | 0.9822078447230085     |
| `po`     | 1.2272254421162134     |
| `pc`     | 1.205827632480371      |
| `e1`     | 0.00010337780767834583 |
| `e2`     | 0.00010219271972776808 |
| `v1`     | 2.0045420261850617e-06 |
| `v2`     | 1.373839551967266e-06  |
| `s2`     | 0.00010267464299824543 |

### Contribute

Have you implemented the estimator in a new programming language? If you want your implementation to be included in this repository, please open a [pull request](https://github.com/eguidotti/bidask/pulls) 