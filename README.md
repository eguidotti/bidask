# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

This [repository](https://github.com/eguidotti/bidask/) implements an efficient estimator of the effective bid-ask spread from open, high, low, and close prices as described in:

> Ardia, D., Guidotti, E., Kroencke, T.A. (2024). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. *Journal of Financial Economics*, 161, 103916. [doi: 10.1016/j.jfineco.2024.103916](https://doi.org/10.1016/j.jfineco.2024.103916)

The estimator is available in:

[C++](https://github.com/eguidotti/bidask/tree/main/c++) | [Julia](https://github.com/eguidotti/bidask/tree/main/julia) | [MATLAB](https://github.com/eguidotti/bidask/tree/main/matlab) | [Python](https://github.com/eguidotti/bidask/tree/main/python) | [R](https://github.com/eguidotti/bidask/tree/main/r) | [SAS](https://github.com/eguidotti/bidask/tree/main/sas)

You can also check the [pseudocode](https://github.com/eguidotti/bidask/tree/main/pseudocode) to implement the estimator in any programming language. 

## Contribute

If you implement the estimator in a new programming language and want your implementation to be included in this repository, please open a [pull request](https://github.com/eguidotti/bidask/pulls).

## Open data

The following datasets are available to download:

| Download                                       | Dataset                                              | Description                                                  |
| ---------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------ |
| [download](https://doi.org/10.7910/DVN/YAY4H6) | Bid-Ask Spread Estimates for U.S. Stocks in CRSP     | Contains monthly estimates of the effective bid-ask spread for each stock in the CRSP U.S. Stock database |
| [download](https://doi.org/10.7910/DVN/9AVA2B) | Bid-Ask Spread Estimates for Crypto Pairs in Binance | Contains monthly estimates of the effective bid-ask spread for crypto pairs listed in Binance |

## Replication code

All code to replicate the paper is available [here](https://doi.org/10.7910/DVN/G8DPBM). The code meets the requirements of the [cascad](https://www.cascad.tech/certification/145-efficient-estimation-of-bid-ask-spreads-from-open-high-low-and-close-prices/) reproducibility policy for a rating of RRR.

## Related works

You can browse publications related to the paper [here](https://scholar.google.com/scholar?cites=2115798896240699437).

## Terms of use

All code is released under the [GPL-3.0](https://github.com/eguidotti/bidask/?tab=GPL-3.0-1-ov-file#GPL-3.0-1-ov-file) license. All data are released under the [CC BY 4.0](http://creativecommons.org/licenses/by/4.0) license. When using any data or code from this repository, you agree to:

- cite [Ardia, Guidotti, & Kroencke (2024)](https://doi.org/10.1016/j.jfineco.2024.103916) as indicated below
- place the link [https://github.com/eguidotti/bidask](https://github.com/eguidotti/bidask) in a footnote to help others find this repository

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