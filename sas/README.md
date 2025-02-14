# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements the efficient estimator of bid-ask spreads from open, high, low, and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024): [https://doi.org/10.1016/j.jfineco.2024.103916](https://doi.org/10.1016/j.jfineco.2024.103916)

## Installation

Download the SAS file [`edge.sas`](https://github.com/eguidotti/bidask/tree/main/sas/edge.sas) into your working directory. For instance:

```shell
wget https://github.com/eguidotti/bidask/raw/main/sas/edge.sas
```

## Usage

The code reads a SAS dataset containing open, high, low, close prices for multiple groups, and saves the spread estimates to an output file. Run the file [`edge.sas`](https://github.com/eguidotti/bidask/tree/main/sas/edge.sas) from the command line as follows:

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
| `sign`  | Boolean value (0/1) indicating whether to return signed estimates |

The input prices must be sorted in ascending order of the timestamp within each group. 

The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

## Example

The file [`ohlc.sas7bdat`](ohlc.sas7bdat) contains simulated open, high, low, and close prices as described [here](https://github.com/eguidotti/bidask/tree/main/pseudocode) for two symbols. Download the file into your working directory. For instance:

```bash
wget https://github.com/eguidotti/bidask/raw/main/sas/ohlc.sas7bdat
```

Estimate the spread for each symbol:

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

