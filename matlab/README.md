# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimation procedure of the bid-ask spread from Open, High, Low, and Close prices as proposed in Ardia, Guidotti, Kroencke (2021): https://www.ssrn.com/abstract=3892335

## Installation

This folder contains the MATLAB implementation in the file [`edge.m`](https://github.com/eguidotti/bidask/tree/main/matlab/edge.m)

## Usage

Estimate the spread

```c++
edge(open, high, low, close)
```

- `open`: vector of Open prices with size `T` x `1`
- `high`: vector of High prices with size `T` x `1`
- `low`: vector of Low prices with size `T` x `1`
- `close`: vector of Close prices with size `T` x `1`

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
