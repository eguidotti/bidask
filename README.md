# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

This [repository](https://github.com/eguidotti/bidask/) implements the efficient estimator of the effective bid-ask spread from open, high, low, and close prices described in:

> Ardia, D., Guidotti, E., Kroencke, T.A. (2024). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. *Journal of Financial Economics*, 161, 103916. [doi: 10.1016/j.jfineco.2024.103916](https://doi.org/10.1016/j.jfineco.2024.103916)

The estimator is available in:

[C++](https://github.com/eguidotti/bidask/tree/main/c++) | [Julia](https://github.com/eguidotti/bidask/tree/main/julia) | [MATLAB](https://github.com/eguidotti/bidask/tree/main/matlab) | [Python](https://github.com/eguidotti/bidask/tree/main/python) | [R](https://github.com/eguidotti/bidask/tree/main/r) | [SAS](https://github.com/eguidotti/bidask/tree/main/sas)

You can also check the [pseudocode](https://github.com/eguidotti/bidask/tree/main/pseudocode) to implement the estimator in any programming language. If you implement the estimator in a new programming language and want your implementation included in the repository, please open a [pull request](https://github.com/eguidotti/bidask/pulls).

## Open data

The following datasets are available to download:

| Download                                       | Dataset                                              | Description                                                  |
| ---------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------ |
| [download](https://doi.org/10.7910/DVN/YAY4H6) | Bid-Ask Spread Estimates for U.S. Stocks in CRSP     | Contains monthly estimates of the effective bid-ask spread for each stock in the CRSP U.S. Stock database |
| [download](https://doi.org/10.7910/DVN/9AVA2B) | Bid-Ask Spread Estimates for Crypto Pairs in Binance | Contains monthly estimates of the effective bid-ask spread for crypto pairs listed in Binance |

## FAQ 

> Each transaction price may generally include a different bid-ask spread, but the estimator only returns a single estimate given a sample of open, high, low, and close prices. What is the estimator computing exactly?

- The estimator estimates the root mean square effective spread within the sample period.

> What is the minimum number of observations required by the estimator?

- The estimator requires at least 3 observations.

> What is the recommended number of observations to use? 

- There is no one-size-fits-all solution.  For instance, using a few daily prices would provide estimates closer to the spread in those days but with potentially large estimation uncertainty. Using one year of daily prices would provide more precise estimates, but for the average (more precisely, root mean square) spread in the whole year. For more information, see https://github.com/eguidotti/bidask/issues/2

> Does the estimator work with intraday data?

- Yes, the estimator can be used with intraday data. 

> What is the recommended frequency to use? 

- Generally, the higher the frequency, the better (e.g., minute prices are preferable to hourly and daily prices). However, this depends on the underlying asset's trading frequency. For instance, weekly prices should be considered for assets that trade, on average, less than once per day. More generally, the frequency should be chosen so that the average number of trades per period is at least two. The estimation variance may increase significantly below this limit. 

> Does the estimator work with tick data?

- The estimator does not natively support tick data. However, it is possible to aggregate tick data into open, high, low, and close prices and apply the estimator.

> How to handle non-positive estimates?

- By default, the estimator returns the absolute value of the estimates. This is generally a good option if you are interested in point estimates, but may create a small-sample bias if the estimates are used for averaging or regression studies. To reduce this source of bias, you can compute signed estimates with the argument `sign=False` and reset negative values to zero. Keeping negative values is not recommended because more negative estimates are typically associated with larger spreads empirically. For more information, see https://github.com/eguidotti/bidask/issues/3

> Does the estimator work with missing values?

- Yes, the estimator works with missing values out-of-the-box. It is recommended to keep missing values and use a regular time grid instead of dropping missing values and using an irregular time grid. For more information, see https://github.com/eguidotti/bidask/issues/16

> Do the functions `edge` and `edge_rolling` produce the same results?

- The function `edge_rolling` is a version of `edge` optimized for fast calculations over rolling windows. The two functions produce the same estimates when there are no missing values. If missing values are present, the two functions may provide slightly different estimates due to how missing values are handled, but both estimates are consistent.

## Replication code

All code to replicate the paper is available [here](https://doi.org/10.7910/DVN/G8DPBM). The code meets the requirements of the [cascad](https://www.cascad.tech/certification/145-efficient-estimation-of-bid-ask-spreads-from-open-high-low-and-close-prices/) reproducibility policy for a rating of RRR.

## Related works

You can browse publications related to the paper [here](https://scholar.google.com/scholar?cites=2115798896240699437).

## Terms of use

All code is released under the [MIT](https://github.com/eguidotti/bidask?tab=MIT-1-ov-file#readme) license. All data are released under the [CC BY 4.0](http://creativecommons.org/licenses/by/4.0) license. When using any data or code from this repository, please cite the reference indicated below.

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