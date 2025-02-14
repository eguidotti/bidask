# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimator of bid-ask spreads from open, high, low, and close prices.

## Installation

Download the file [`edge.m`](https://github.com/eguidotti/bidask/tree/main/matlab/edge.m) into your working directory.

## Usage

Import the estimator:

```matlab
import edge.*
```

Arguments:

```matlab
edge(open, high, low, close, sign=false)
```

| field   | description                                |
| ------- | ------------------------------------------ |
| `open`  | Vector of open prices with size `T` x `1`  |
| `high`  | Vector of high prices with size `T` x `1`  |
| `low`   | Vector of low prices with size `T` x `1`   |
| `close` | Vector of close prices with size `T` x `1` |
| `sign`  | Whether to return signed estimates         |

The input prices must be sorted in ascending order of the timestamp. 

The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

## Example

```matlab
import edge.*

df = readmatrix('https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc-miss.csv');
edge(df(:,1), df(:,2), df(:,3), df(:,4))
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

