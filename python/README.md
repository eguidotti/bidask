# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimator of bid-ask spreads from open, high, low, and close 
prices as described in [Ardia, Guidotti, & Kroencke (2021)](https://www.ssrn.com/abstract=3892335).


## Installation

Install this package with:

```bash
pip install bidask
```

## Usage

Import the estimator:

```python
from bidask import edge
```

Arguments:

```python
edge(open, high, low, close, sign=False)
```

| field   | description                                 |
| ------- | ------------------------------------------- |
| `open`  | Array-like vector of open prices            |
| `high`  | Array-like vector of high prices            |
| `low`   | Array-like vector of low prices             |
| `close` | Array-like vector of close prices           |
| `sign`  | Whether signed estimates should be returned |

The input prices must be sorted in ascending order of the timestamp. 

The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

## Example

```python
import pandas as pd
from bidask import edge

df = pd.read_csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")
edge(df.Open, df.High, df.Low, df.Close)
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
