# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimator of bid-ask spreads from open, high, low, and close 
prices as described in [Ardia, Guidotti, & Kroencke (2021)](https://www.ssrn.com/abstract=3892335).

## Installation

Download the SAS file [`edge.sas`](https://github.com/eguidotti/bidask/tree/main/sas/edge.sas) into your working directory. For instance:

```shell
wget https://github.com/eguidotti/bidask/raw/main/sas/edge.sas
```

## Usage

The file reads a SAS dataset containing open, high, low, close prices for multiple groups, and saves the spread estimates to an output file. Run the file [`edge.sas`](https://github.com/eguidotti/bidask/tree/main/sas/edge.sas) from the command line as follows:

```SAS
sas edge.sas \
  -set in <...> \
  -set out <...> \
  -set by <...> \
  -set open <...> \
  -set high <...> \
  -set low <...> \
  -set close <...> \
  -set sign <...>
```

| field   | description                                                  |
| ------- | ------------------------------------------------------------ |
| `in`    | The path to a SAS dataset containing open, high, low, and close prices for multiple groups |
| `out`   | The name of the file to output spread estimates. See [here](https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/acpcref/p1d0tocg3njhmfn1d4ld2covlwm0.htm) for supported file extensions |
| `group` | Comma separated list of column(s) to group by; e.g., `symbol` or `date,symbol` |
| `open`  | The name of the column containing open prices                |
| `high`  | The name of the column containing high prices                |
| `low`   | The name of the column containing low prices                 |
| `close` | The name of the column containing close prices               |
| `sign`  | Boolean value (0/1) indicating whether signed estimates should be returned |

The input prices must be sorted in ascending order of the timestamp within each group. 

The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

## Example

The file [`ohlc.sas7bdat`](ohlc.sas7bdat) contains simulated open, high, low, and close prices as described [here](https://github.com/eguidotti/bidask/tree/main/pseudocode) for two symbols. Download the file into your working directory. For instance:

```bash
wget https://github.com/eguidotti/bidask/raw/main/sas/ohlc.sas7bdat
```

Then, estimate the spread for each symbol:

```SAS
sas edge.sas \
  -set in ohlc.sas7bdat \
  -set out edge.csv \
  -set by Symbol \
  -set open Open \
  -set high High \
  -set low Low \
  -set close Close \
  -set sign 0
```

The output file `edge.csv` contains the following estimates:

| Symbol | EDGE         |
| ------ | ------------ |
| A      | 0.0101849035 |
| B      | 0.0101849035 |

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
