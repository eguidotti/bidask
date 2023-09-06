# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimator of bid-ask spreads from open, high, low, and close 
prices as described in [Ardia, Guidotti, & Kroencke (2021)](https://www.ssrn.com/abstract=3892335).

## Installation

Install this package with:

```R
install.packages("bidask")
```

## Usage

Load the library:

```R
library("bidask")
```

Simulate a price process with spread 1%:

```R
x <- sim(spread = 0.01)
```

Estimate the spread. A value of 0.01 corresponds to a spread of 1%:

```r
edge(x$Open, x$High, x$Low, x$Close)
```

By default this is equivalent to:

```r
spread(x)
```

Use a rolling window of 21 periods:

```r
spread(x, width = 21)
```

Compute the spread for each month:

```r
ep <- xts::endpoints(x, on = "months")
spread(x, width = ep)
```

Use multiple estimators:

```r
spread(x, method = c("EDGE", "AR", "CS", "ROLL", "OHLC", "OHL.CHL"))
```

Full documentation available on [CRAN](https://cran.r-project.org/package=bidask/bidask.pdf)

## Cite as

*Ardia, David and Guidotti, Emanuele and Kroencke, Tim Alexander, "Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices". Available at SSRN: https://ssrn.com/abstract=3892335*

A BibTex  entry for LaTeX users is:

```bibtex
@unpublished{edge2021,
    author = {Ardia, David and Guidotti, Emanuele and Kroencke, Tim},
    title  = {Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices},
    year   = {2021},
    note   = {Available at SSRN}
    url    = {https://ssrn.com/abstract=3892335}
}
```
