# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimator of bid-ask spreads from open, high, low, and close 
prices as described in [Ardia, Guidotti, & Kroencke (2021)](https://www.ssrn.com/abstract=3892335).

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

| field   | description                                 |
| ------- | ------------------------------------------- |
| `open`  | Vector of open prices with size `T` x `1`   |
| `high`  | Vector of high prices with size `T` x `1`   |
| `low`   | Vector of low prices with size `T` x `1`    |
| `close` | Vector of close prices with size `T` x `1`  |
| `sign`  | Whether signed estimates should be returned |

The input prices must be sorted in ascending order of the timestamp. 

The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

## Example

```matlab
import edge.*

df = csvread(websave(tempname, 'https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv'), 1, 0);
edge(df(:,1), df(:,2), df(:,3), df(:,4))
```

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
