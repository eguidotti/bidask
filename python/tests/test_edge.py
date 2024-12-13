import pytest
import numpy as np
import pandas as pd
from bidask import edge, rolling_edge


def test_edge():
    """
    Compares the `edge` function to the known test case
    """
    df = pd.read_csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")

    estimate = edge(df.Open, df.High, df.Low, df.Close)
    assert estimate == pytest.approx(0.0101849034905478)
  
    estimate = edge(df.Open[0:10], df.High[0:10], df.Low[0:10], df.Close[0:10], True)
    assert estimate == pytest.approx(-0.016889917516422)

    assert np.isnan(edge(
        [18.21, 17.61, 17.61],
        [18.21, 17.61, 17.61],
        [17.61, 17.61, 17.61],
        [17.61, 17.61, 17.61]
    ))

@pytest.mark.parametrize("window_size", [3,42,1000])
def test_edge_rolling_consistency(window_size):
    """
    Compares the rolling vectorized implementation to the original function.

    NOTE: There is a problem with window_size = 2 or 1; `edge` produces 
    some or all NaNs, respectively, while the rolling implementation produces 
    small (<1e-8) or zero values, respectively, at these same times.
    """
    df = pd.read_csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")

    rolling_estimates = rolling_edge(df=df, window=window_size)

    # Compute the expected results by manually looping with `edge`.

    # Due to lag handling via e.g. h1:=h[:-1], h:=h[1:] in `edge`,
    # the oldest date is discarded for "present" prices and
    # the lagged prices include this oldest date. Hence, the `edge`
    # function applied to prices at times {t=a-window_size, ..., t=a}
    # correspond to the pd.rolling(window_size) estimate @ t=a.
    window_size_edge = window_size + 1 

    expected_estimates = [np.nan] * (window_size)

    for t0 in range(len(df) + 1 - window_size_edge):
        t = t0 + window_size_edge
        est = edge(
            df.Open.values[t0:t],
            df.High.values[t0:t],
            df.Low.values[t0:t],
            df.Close.values[t0:t]
        )
        expected_estimates.append(est)

    expected_estimates = np.array(expected_estimates)

    # Compare the rolling vectorized results to the expected results
    np.testing.assert_allclose(
        actual = rolling_estimates,
        desired = expected_estimates,
        rtol=1e-8,
        atol=1e-8,
        err_msg="Rolling vectorized results do not match the original function results on a per-window basis."
    )