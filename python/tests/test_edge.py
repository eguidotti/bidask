import pytest
import numpy as np
import pandas as pd
from bidask import edge, edge_rolling, edge_expanding


df = pd.read_csv(
    "https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv"
)

df_miss = pd.read_csv(
    "https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc-miss.csv"
)


def test_edge():
    """
    Compares the `edge` function to the known test case
    """
    estimate = edge(df.Open, df.High, df.Low, df.Close)
    assert estimate == pytest.approx(0.0101849034905478)
  
    estimate = edge(df.Open[0:10], df.High[0:10], df.Low[0:10], df.Close[0:10], True)
    assert estimate == pytest.approx(-0.016889917516422)

    estimate = edge(df_miss.Open, df_miss.High, df_miss.Low, df_miss.Close)
    assert estimate == pytest.approx(0.01013284969780197)

    assert np.isnan(edge(
        [18.21, 17.61, 17.61],
        [18.21, 17.61, 17.61],
        [17.61, 17.61, 17.61],
        [17.61, 17.61, 17.61]
    ))


@pytest.mark.parametrize("window", [1, 2, 3, 4, 42, 1000])
@pytest.mark.parametrize("sign", [True, False])
@pytest.mark.parametrize("step", [1, 2, 5, 10])
def test_edge_rolling(window: int, step: int, sign: bool):
    """
    Compares the rolling vectorized implementation to the original function.

    Parameters
    ----------
    - `window` : int
        The rolling window size.
    - `step`: int
        Evaluate the window at every step result.
    - `sign`: bool
        Whether to use signed estimates.
    """
    rolling_estimates = edge_rolling(df=df, window=window, step=step, sign=sign)
    assert isinstance(rolling_estimates, pd.Series)

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
        
    np.testing.assert_allclose(
        actual = rolling_estimates,
        desired = expected_estimates,
        rtol=1e-8,
        atol=1e-8,
        err_msg='Rolling estimates do not match expected estimates'
    )


@pytest.mark.parametrize("min_periods", [0, 1, 2, 3, 42, 1000])
@pytest.mark.parametrize("sign", [True, False])
def test_edge_expanding(min_periods: int, sign: bool):
    """
    Compares the expanding vectorized implementation to the original function.

    Parameters
    ----------
    - `min_periods` : int
        Minimum number of observations in window required to have a value; otherwise, result is np.nan.
    - `sign`: bool
        Whether to use signed estimates.
    """
    expanding_estimates = edge_expanding(df=df, min_periods=min_periods, sign=sign)
    assert isinstance(expanding_estimates, pd.Series)

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
        
    np.testing.assert_allclose(
        actual = expanding_estimates,
        desired = expected_estimates,
        rtol=1e-8,
        atol=1e-8,
        err_msg='Expanding estimates do not match expected estimates'
    )
