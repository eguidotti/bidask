# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimation procedure of the bid-ask spread from Open, High, Low, and Close prices as proposed in [Ardia, Guidotti, Kroencke (2021)](https://www.ssrn.com/abstract=3892335)

## Installation

Download the SAS file [`edge.sas`](https://github.com/eguidotti/bidask/tree/main/sas/edge.sas) into your working directory.

## Usage

The file reads a SAS dataset containing open, high, low, close prices (for multiple groups) and saves the spread estimates into a (e.g., csv) file. Run the file [`edge.sas`](https://github.com/eguidotti/bidask/tree/main/sas/edge.sas) from the command line:

```SAS
sas edge.sas \
  -set in <DATA> \
  -set out <FILE> \
  -set by <GROUP> \
  -set open <OPEN> \
  -set high <HIGH> \
  -set low <LOW> \
  -set close <CLOSE> 
```

- `<DATA>`: the path to the file containing Open, High, Low, Close prices (for multiple groups)
- `<FILE>`: the path to store the spread estimates (for each group). See [here](https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/acpcref/p1d0tocg3njhmfn1d4ld2covlwm0.htm) for supported file extensions
- `<GROUP>`: comma separated list of column(s) to group by; e.g., `symbol` or `date,symbol`
- `<OPEN>`: the column containing Open prices
- `<HIGH>`: the column containing High prices
- `<LOW>`: the column containing Low prices
- `<CLOSE>`: the column containing Close prices

Prices must be sorted in ascending order of the timestamp within each group. 

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
