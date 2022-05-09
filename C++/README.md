# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimation procedure of the bid-ask spread from Open, High, Low, and Close prices as proposed in Ardia, Guidotti, Kroencke (2021): https://www.ssrn.com/abstract=3892335

## Installation

This folder contains the C++ source file [`edge.cpp`](https://github.com/eguidotti/bidask/tree/main/C++/edge.cpp) and the corresponding header [`edge.h`](https://github.com/eguidotti/bidask/tree/main/C++/edge.h)

## Usage

Estimate the spread

```python
edge(open, high, low, close)
```

- `open`: standard `vector<double>` of Open prices.
- `high`: standard `vector<double>` of High prices.
- `low`: standard`vector<double>` of Low prices.
- `close`: standard `vector<double>` of Close prices.

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
