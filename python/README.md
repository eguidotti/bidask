# Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimator of bid-ask spreads from open, high, low, and close prices.


## Installation

```bash
pip install bidask
```

## Usage

There are three functions in this package. The function `edge` computes a single bid-ask spread estimate from vectors of open, high, low, and close prices. The functions `edge_rolling` and `edge_expanding` are optimized for fast calculations over rolling and expanding windows, respectively.

```python
from bidask import edge, edge_rolling, edge_expanding
```

### Function: `edge`

The input prices must be sorted in ascending order of the timestamp. The output value is the spread estimate. A value of 0.01 corresponds to a spread of 1%.

```python
edge(open, high, low, close, sign=False)
```

| field   | description                        |
| ------- | ---------------------------------- |
| `open`  | Array-like vector of open prices   |
| `high`  | Array-like vector of high prices   |
| `low`   | Array-like vector of low prices    |
| `close` | Array-like vector of close prices  |
| `sign`  | Whether to return signed estimates |

### Function: `edge_rolling`

Implements a rolling window calculation of `edge`. The input is a pandas data frame. The output is a pandas series of rolling spread estimates. A value of 0.01 corresponds to a spread of 1%. 

```python
edge_rolling(df, sign=False, **kwargs)
```

| field      | description                                                  |
| ---------- | ------------------------------------------------------------ |
| `df`       | Data frame with columns 'open', 'high', 'low', 'close' (case-insensitive). |
| `sign`     | Whether to return signed estimates                           |
| `**kwargs` | Additional keyword arguments to pass to the pandas rolling function. For more information about the rolling parameters, see [here](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.rolling.html) |

### Function: `edge_expanding`

Implements an expanding window calculation of `edge`. The input is a pandas data frame. The output is a pandas series of expanding spread estimates. A value of 0.01 corresponds to a spread of 1%. 

```python
edge_expanding(df, sign=False, **kwargs)
```

| field      | description                                                  |
| ---------- | ------------------------------------------------------------ |
| `df`       | Data frame with columns 'open', 'high', 'low', 'close' (case-insensitive). |
| `sign`     | Whether to return signed estimates                           |
| `**kwargs` | Additional keyword arguments to pass to the pandas expanding function. For more information about the expanding parameters, see [here](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.expanding.html) |

## Examples

Load the test data.

```python
import pandas as pd
df = pd.read_csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")
```

Compute the spread estimate using the full sample data.

```py
from bidask import edge
edge(df.Open, df.High, df.Low, df.Close)
```

Compute rolling estimates using a window size of 21 periods.

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

