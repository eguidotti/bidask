# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements the efficient estimator of bid-ask spreads from open, high, low, and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024): [https://doi.org/10.1016/j.jfineco.2024.103916](https://doi.org/10.1016/j.jfineco.2024.103916)

## Installation

```R
install.packages("bidask")
```

## Usage

There are three functions in this package. The function `edge` computes a single bid-ask spread estimate from vectors of open, high, low, and close prices. The function `spread` is optimized for fast calculations over rolling windows, and implements additional estimators. The function `sim` simulates a time series of open, high, low, and close prices. The full [documentation](https://CRAN.R-project.org/package=bidask/bidask.pdf) is available on [CRAN](https://cran.r-project.org/package=bidask). A [vignette](https://cran.r-project.org/package=bidask/vignettes/bidask.html) is also available.

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

### Functions `spread` and `sim`

For more information about these functions, see the [documentation](https://CRAN.R-project.org/package=bidask/bidask.pdf). 

## Example

```R
library("bidask")

df = read.csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")
edge(df$Open, df$High, df$Low, df$Close)
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

