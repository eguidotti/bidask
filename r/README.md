# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements the efficient estimator of bid-ask spreads from open, high, low, and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024): [https://doi.org/10.1016/j.jfineco.2024.103916](https://doi.org/10.1016/j.jfineco.2024.103916)

## Installation

```R
install.packages("bidask")
```

## Usage

This package implements the following functions. The function `edge` computes a single bid-ask spread estimate from vectors of open, high, low, and close prices. The functions `edge_rolling` and `edge_expanding` are optimized for fast calculations over rolling and expanding windows, respectively. The function `spread` provides additional functionalities for `xts` objects and implements additional estimators. The function `sim` simulates a time series of open, high, low, and close prices. The main functions are presented below. The full [documentation](https://CRAN.R-project.org/package=bidask/bidask.pdf) is available on [CRAN](https://cran.r-project.org/package=bidask) and a [vignette](https://cran.r-project.org/package=bidask/vignettes/bidask.html) is also available.

```R
library("bidask")
```

### Function `edge`

The input prices must be sorted in ascending order of the timestamp. The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

```R
edge(open, high, low, close, sign=FALSE)
```

| field   | description                         |
| ------- | ----------------------------------- |
| `open`  | Numeric vector of open prices.      |
| `high`  | Numeric vector of high prices.      |
| `low`   | Numeric vector of low prices.       |
| `close` | Numeric vector of close prices.     |
| `sign`  | Whether to return signed estimates. |

### Function: `edge_rolling`

Implements a rolling window calculation of `edge`. The output is a vector of rolling spread estimates. A value of 0.01 corresponds to a spread of 1%. This function always returns a result of the same length as the input prices. 

```R
edge_rolling(open, high, low, close, width, sign=FALSE, na.rm=FALSE)
```

| field   | description                                                  |
| ------- | ------------------------------------------------------------ |
| `open`  | Numeric vector of open prices.                               |
| `high`  | Numeric vector of high prices.                               |
| `low`   | Numeric vector of low prices.                                |
| `close` | Numeric vector of close prices.                              |
| `width` | If an integer, the width of the rolling window. If a vector with the same length of the input prices, the width of the window corresponding to each observation. Otherwise, a vector of endpoints. See examples. |
| `sign`  | Whether to return signed estimates.                          |
| `na.rm` | Whether to ignore missing values.                            |

### Function: `edge_expanding`

Implements an expanding window calculation of `edge`. The output is a vector of expanding spread estimates. A value of 0.01 corresponds to a spread of 1%. This function always returns a result of the same length as the input prices. 

```R
edge_expanding(open, high, low, close, sign=FALSE, na.rm=TRUE)
```

| field   | description                         |
| ------- | ----------------------------------- |
| `open`  | Numeric vector of open prices.      |
| `high`  | Numeric vector of high prices.      |
| `low`   | Numeric vector of low prices.       |
| `close` | Numeric vector of close prices.     |
| `sign`  | Whether to return signed estimates. |
| `na.rm` | Whether to ignore missing values.   |

## Examples

Load the test data.

```R
library("bidask")
x = read.csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")
```

Compute the spread estimate using all the observations.

```R
edge(x$Open, x$High, x$Low, x$Close)
```

Compute rolling estimates using a window of 21 observations.

```R
edge_rolling(x$Open, x$High, x$Low, x$Close, width = 21)
```

Estimate the spread using custom endpoints.

```R
edge_rolling(x$Open, x$High, x$Low, x$Close, width = c(3, 35, 100))
```

Estimate the spread using an expanding window

```R
edge_expanding(x$Open, x$High, x$Low, x$Close, na.rm = FALSE)
```

## Cite as

> Ardia, D., Guidotti, E., Kroencke, T.A. (2024). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. *Journal of Financial Economics*, 161, 103916. [doi: 10.1016/j.jfineco.2024.103916](https://doi.org/10.1016/j.jfineco.2024.103916)

A BibTex  entry for LaTeX users is:

```bibtex
@article{edge,
  title = {Efficient estimation of bid–ask spreads from open, high, low, and close prices},
  journal = {Journal of Financial Economics},
  volume = {161},
  pages = {103916},
  year = {2024},
  doi = {https://doi.org/10.1016/j.jfineco.2024.103916},
  author = {David Ardia and Emanuele Guidotti and Tim A. Kroencke},
}
```

