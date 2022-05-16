# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimation procedure of the bid-ask spread from Open, High, Low, and Close prices as proposed in [Ardia, Guidotti, Kroencke (2021)](https://www.ssrn.com/abstract=3892335)

## Installation

Install this package with:

```bash
pip install bidask
```

## Usage

Import the estimator

```python
from bidask import edge
```

Estimate the spread

```python
edge(open, high, low, close)
```

- `open`: array-like vector of Open prices.
- `high`: array-like vector of High prices.
- `low`: array-like vector of Low prices.
- `close`: array-like vector of Close prices.

Prices must be sorted in ascending order of the timestamp.

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
