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

Arguments:

```R
edge(open, high, low, close, sign=FALSE)
```

| field   | description                                 |
| ------- | ------------------------------------------- |
| `open`  | Numeric vector of open prices               |
| `high`  | Numeric vector of high prices               |
| `low`   | Numeric vector of low prices                |
| `close` | Numeric vector of close prices              |
| `sign`  | Whether signed estimates should be returned |

The input prices must be sorted in ascending order of the timestamp.

The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

## Example

```R
library("bidask")

df = read.csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")
edge(df$Open, df$High, df$Low, df$Close)
```

## Cite as

*Ardia, David and Guidotti, Emanuele and Kroencke, Tim Alexander, "Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices". Available at SSRN: https://www.ssrn.com/abstract=3892335* 

A BibTex  entry for LaTeX users is:

```bibtex
@unpublished{edge2021,
    author = {Ardia, David and Guidotti, Emanuele and Kroencke, Tim},
    title  = {Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices},
    year   = {2021},
    note   = {Available at SSRN}
    url    = {https://www.ssrn.com/abstract=3892335}
}
```
