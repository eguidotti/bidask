import numpy as np
import pandas as pd
from typing import Optional, Union

def edge(
        open: pd.Series, 
        high: pd.Series, 
        low: pd.Series, 
        close: pd.Series, 
        sign: bool = False, 
        mid_price: Union[str, pd.Series] = "hl",
        smoothing: Optional[str] = None,
        window: Optional[int] = None, 
):
    """
    Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

    Implements an efficient estimator of bid-ask spreads from open, high, low, and close prices 
    as described in Ardia, Guidotti, & Kroencke (2021) -> https://www.ssrn.com/abstract=3892335

    Prices must be sorted in ascending order of the timestamp.

    Parameters
    ----------
    - `open`: array-like vector of open prices
    - `high`: array-like vector of high prices
    - `low`: array-like vector of low prices
    - `close`: array-like vector of close prices
    - `sign`: whether signed estimates should be returned
    - `window`: the window size for the smoothing of the estimator, None returns single estimate.
    - `smoothing`: the type of smoothing to be used. Either 'ma' for moving average or 'ema' for exponential moving average
    - `mid_price`: either array-lie of mid prices to use or string to indicate calculation
                    - 'hl': (high + low) / 2
                    - 'oc': (open + close) / 2
                    - 'hlc': (high + low + close) / 3
                    - 'ohl': (open + high + low) / 3
                    - 'ohlc': (open + high + low + close) / 4

    Returns
    -------
    The array-like rolling spread estimate. A value of 0.01 corresponds to a spread of 1%.
    """

    # handle smoothing type
    def _smooth(input, smoothing, window):
        if smoothing == "ma":
            return input.rolling(window).mean()
        elif smoothing == "ema":
            return input.ewm(span=window).mean()
        elif smoothing is None:
            return input.mean()
        else:
            raise ValueError("Invalid smoothing type. Must be 'ma' or 'ema'")
        
    # parse mid_price string to get mid_price
    def _get_mid_price(open, high, low, close, mid_price_str):
        if mid_price_str == 'hl':
            return (high + low) / 2
        elif mid_price_str == 'oc':
            return (open + close) / 2
        elif mid_price_str == 'hlc':
            return (high + low + close) / 3
        elif mid_price_str == 'ohl':
            return (open + high + low) / 3
        elif mid_price_str == 'ohlc':
            return (open + high + low + close) / 4
        else:
            raise ValueError("Invalid mid_price string. Must be 'hl', 'oc', 'hlc', 'ohl', or 'ohlc'")

    # get mid_price before taking log to avoid bias   
    if isinstance(mid_price, str):
        mid_price = _get_mid_price(open, high, low, close, mid_price)

    open = pd.Series(np.log(open))
    high = pd.Series(np.log(high))
    low = pd.Series(np.log(low))
    close = pd.Series(np.log(close))
    mid_price = pd.Series(np.log(mid_price))

    tau = np.logical_or(high != low, low != close.shift(1))[1:]
    phi1 = np.logical_and(open != high, tau)[1:]
    phi2 = np.logical_and(open != low, tau)[1:]
    phi3 = np.logical_and(close.shift(1) != high.shift(1), tau)[1:]
    phi4 = np.logical_and(close.shift(1) != low.shift(1), tau)[1:]

    pt = _smooth(tau, smoothing, window)
    po = _smooth(phi1, smoothing, window) + _smooth(phi2, smoothing, window)
    pc = _smooth(phi3, smoothing, window) + _smooth(phi4, smoothing, window)

    r1 = mid_price - open
    r2 = open - close.shift(1)
    r3 = mid_price - close.shift(1)
    r4 = close.shift(1) - mid_price.shift(1)
    r5 = open - close.shift(1)

    d1 = r1 - tau * _smooth(r1, smoothing, window) / pt
    d3 = r3 - tau * _smooth(r3, smoothing, window) / pt
    d5 = r5 - tau * _smooth(r5, smoothing, window) / pt

    x1 = -4./po*d1*r2 -4./pc*d3*r4
    x2 = -4./po*d1*r5 -4./pc*d5*r4

    e1 = _smooth(x1, smoothing, window)
    e2 = _smooth(x2, smoothing, window)

    v1 = _smooth(x1**2, smoothing, window) - e1**2
    v2 = _smooth(x2**2, smoothing, window) - e2**2

    s2 = (v2*e1 + v1*e2) / (v1 + v2)

    s = np.sqrt(np.abs(s2))
    if sign:
        s = s * np.sign(s2)

    if isinstance(s, pd.Series):
        s = s.where((pt!=0)&(po!=0)&(pc!=0), np.nan)
    elif isinstance(s, float):
        if not (pt and po and pc):
            s = np.nan

    return s