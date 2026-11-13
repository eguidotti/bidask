# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements the efficient estimator of bid-ask spreads from open, high, low, and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024): [https://doi.org/10.1016/j.jfineco.2024.103916](https://doi.org/10.1016/j.jfineco.2024.103916)


## Installation

```bash
pip install bidask
```

## Usage

The function `edge` computes a single bid-ask spread estimate from vectors of open, high, low, and close prices. The functions `edge_rolling` and `edge_expanding` are optimized for fast calculations over rolling and expanding windows, respectively. The function `spread` is a port of the R function `spread` and implements the full family of estimators (EDGE, OHL, OHLC, CHL, CHLO, AR, AR2, CS, CS2, ROLL).

```python
from bidask import edge, edge_rolling, edge_expanding, spread
```

### Function: `edge`

The input prices must be sorted in ascending order of the timestamp. The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

```python
edge(open, high, low, close, sign=False)
```

| field   | description                         |
| ------- | ----------------------------------- |
| `open`  | Array-like vector of open prices.   |
| `high`  | Array-like vector of high prices.   |
| `low`   | Array-like vector of low prices.    |
| `close` | Array-like vector of close prices.  |
| `sign`  | Whether to return signed estimates. |

### Function: `edge_rolling`

Implements a rolling window calculation of `edge`. The input is a pandas data frame. The output is a pandas series of rolling spread estimates. A value of 0.01 corresponds to a spread of 1%.

```python
edge_rolling(df, window, sign=False, **kwargs)
```

| field      | description                                                  |
| ---------- | ------------------------------------------------------------ |
| `df`       | Data frame with columns 'open', 'high', 'low', 'close' (case-insensitive). |
| `window`   | Size of the moving window. For more information about this parameter, see [here](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.rolling.html). |
| `sign`     | Whether to return signed estimates.                          |
| `**kwargs` | Additional keyword arguments to pass to the pandas rolling function. For more information about the rolling parameters, see [here](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.rolling.html). |

### Function: `edge_expanding`

Implements an expanding window calculation of `edge`. The input is a pandas data frame. The output is a pandas series of expanding spread estimates. A value of 0.01 corresponds to a spread of 1%. 

```python
edge_expanding(df, min_periods=1, sign=False)
```

| field         | description                                                  |
| ------------- | ------------------------------------------------------------ |
| `df`          | Data frame with columns 'open', 'high', 'low', 'close' (case-insensitive). |
| `min_periods` | Minimum number of observations in window required to have a value; otherwise, result is `np.nan`. |
| `sign`        | Whether to return signed estimates.                          |

### Function: `spread`

Port of the R function [`bidask::spread`](https://github.com/eguidotti/bidask/tree/main/r). It computes one or more estimators over the full sample, rolling or expanding windows, or custom endpoints. Results match the R package to 1e-10, including missing values and errors.

```python
spread(x, width=None, method="EDGE", sign=False, na_rm=False, by=None)
```

| field    | description |
| -------- | ----------- |
| `x`      | Data frame with columns 'open', 'high', 'low', 'close' (case-insensitive; prefixes such as 'MSFT.Open' are stripped, as in R). Rows sorted by time. |
| `width`  | `None` (default) for one estimate on the full sample. An int for a rolling window. An array with one entry per row for per-row window widths (e.g. `range(1, len(x) + 1)` for an expanding window). Any other array gives 1-based endpoints: one estimate per endpoint after the first. |
| `method` | One or more of `EDGE`, `OHL`, `OHLC`, `CHL`, `CHLO`, `AR`, `AR2`, `CS`, `CS2`, `ROLL`, or `.`-joined combinations of `OHL`/`OHLC`/`CHL`/`CHLO` (e.g. `OHLC.CHLO`). Case-insensitive. |
| `sign`   | Whether to return signed estimates. |
| `na_rm`  | Whether to ignore missing values within each window (R's `na.rm`). |
| `by`     | Python only. Column(s) identifying each series in a long-format panel. Each group is estimated as if `spread` were called on it alone, in one vectorized pass. |

The output is a data frame with one column per method, keeping the rows R keeps. With `width=None` that is the last row. With an int `width`, rows `width` onward. With per-row widths, every row. With endpoints, the endpoint rows. A value of 0.01 corresponds to a spread of 1%.

| Estimator | Reference | R | Python | Python vs. R |
| --- | --- | :-: | :-: | --- |
| `EDGE` | Ardia, Guidotti & Kroencke (JFE, 2024) | ✓ | ✓ | agrees to 1e-10 |
| `OHL`, `OHLC`, `CHL`, `CHLO` | Ardia, Guidotti & Kroencke (JFE, 2024) | ✓ | ✓ | agrees to 1e-10 |
| `AR`, `AR2` | Abdi & Ranaldo (RFS, 2017) | ✓ | ✓ | agrees to 1e-10 |
| `CS`, `CS2` | Corwin & Schultz (JF, 2012) | ✓ | ✓ | agrees to 1e-10 |
| `ROLL` | Roll (JF, 1984) | ✓ | ✓ | agrees to 1e-10 |

Parity is checked on 312 R-generated cases: 12 methods × width (full sample, 1, 2, 3, 21, expanding, endpoints) × `sign` × `na_rm`, on synthetic data, real MSFT minute and daily bars, and edge-case inputs. See `tests/fixtures/`.

**Sign convention.** Most estimators first estimate a squared spread, which can be negative in finite samples. By default they return `sqrt(|s2|)`. With `sign=True` they return `sign(s2) * sqrt(|s2|)`, so negative estimates are kept, not set to zero. `AR2` and `CS2` set negative per-period estimates to zero before averaging, so they are never negative and `sign` has no effect on them.

**Missing, halted and zero-volume periods.** A missing price makes every window that contains it NaN unless `na_rm=True`. Keep halted days as NaN rather than forward-filling them. EDGE and OHL/OHLC/CHL/CHLO skip non-informative bars, where high equals low equals the previous close (typical of zero-volume periods). They return NaN when a window has fewer than two informative bars. AR, CS and ROLL have no such filter, so flat bars pull them toward zero. Prices of 0 or below produce `-inf`/NaN log prices, as in R, with no error.

```py
from bidask import spread
spread(df, method=["EDGE", "AR", "CS", "ROLL"])        # full sample
spread(df, width=21, method="OHLC.CHLO", sign=True)     # rolling
spread(df, width=range(1, len(df) + 1))                 # expanding
spread(df, width=[3, 35, 100])                          # custom endpoints
spread(panel, width=21, method="AR", by="ticker")       # long-format panel
```

## Examples

Load the test data.

```python
import pandas as pd
df = pd.read_csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")
```

Compute the spread estimate using all the observations.

```py
from bidask import edge
edge(df.Open, df.High, df.Low, df.Close)
```

Compute rolling estimates using a window of 21 observations.

```py
from bidask import edge_rolling
edge_rolling(df=df, window=21)
```

Compute expanding estimates starting with a minimum of 21 observations.

```py
from bidask import edge_expanding
edge_expanding(df=df, min_periods=21)
```

## Notes

The rolling estimates:

```py
rolling_estimates = edge_rolling(df=df, window=window, step=step, sign=sign)
```

are equivalent to, but much faster than:

```py
expected_estimates = []
for t in range(0, len(df), step):
    t1 = t + 1
    t0 = t1 - window
    expected_estimates.append(edge(
        df.Open.values[t0:t1],
        df.High.values[t0:t1],
        df.Low.values[t0:t1],
        df.Close.values[t0:t1],
        sign=sign
    ) if t0 >= 0 else np.nan)
```

The expanding estimates:

```py
expanding_estimates = edge_expanding(df=df, min_periods=min_periods, sign=sign)
```

are equivalent to, but much faster than:

```py
expected_estimates = []
for t in range(0, len(df)):
    t1 = t + 1
    expected_estimates.append(edge(
        df.Open.values[0:t1],
        df.High.values[0:t1],
        df.Low.values[0:t1],
        df.Close.values[0:t1],
        sign=sign
    ) if t1 >= min_periods else np.nan)
```

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
