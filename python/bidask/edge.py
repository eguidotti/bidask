import numpy as np


def edge(open: np.array, high: np.array, low: np.array, close: np.array, sign: bool = False) -> float:
    """
    Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

    Implements an efficient estimator of bid-ask spreads from open, high, low, 
    and close prices as described in Ardia, Guidotti, & Kroencke (2024):
    https://doi.org/10.1016/j.jfineco.2024.103916

    Parameters
    ----------
    - `open`: array-like 
        Vector of open prices sorted in ascending order of the timestamp.
    - `high`: array-like 
        Vector of high prices sorted in ascending order of the timestamp.
    - `low`: array-like 
        Vector of low prices sorted in ascending order of the timestamp.
    - `close`: array-like 
        Vector of close prices sorted in ascending order of the timestamp.
    - `sign`: 
        Whether to return signed estimates.

    Returns
    -------
    float
        The spread estimate. A value of 0.01 corresponds to a spread of 1%.
    """
    no, nh, nl, nc = len(open), len(high), len(low), len(close)
    if no != nh or no != nl or no != nc:
        raise ValueError("Open, high, low, and close prices must have the same length")
    
    if no < 3:
        return np.nan

    o = np.log(np.asarray(open))
    h = np.log(np.asarray(high))
    l = np.log(np.asarray(low))
    c = np.log(np.asarray(close))
    m = (h + l) / 2.

    h1, l1, c1, m1 = h[:-1], l[:-1], c[:-1], m[:-1]
    o, h, l, c, m = o[1:], h[1:], l[1:], c[1:], m[1:]

    tau = np.logical_or(h != l, l != c1) 
    phi1 = np.logical_and(o != h, tau)
    phi2 = np.logical_and(o != l, tau)
    phi3 = np.logical_and(c1 != h1, tau)
    phi4 = np.logical_and(c1 != l1, tau)
  
    pt = np.nanmean(tau)
    po = np.nanmean(phi1) + np.nanmean(phi2)
    pc = np.nanmean(phi3) + np.nanmean(phi4)
    
    if pt == 0 or po == 0 or pc == 0:
        return np.nan

    r1 = m-o
    r2 = o-m1
    r3 = m-c1
    r4 = c1-m1
    r5 = o-c1
  
    d1 = r1 - tau * np.nanmean(r1) / pt
    d3 = r3 - tau * np.nanmean(r3) / pt
    d5 = r5 - tau * np.nanmean(r5) / pt
  
    x1 = -4./po*d1*r2 -4./pc*d3*r4 
    x2 = -4./po*d1*r5 -4./pc*d5*r4 
  
    e1 = np.nanmean(x1)
    e2 = np.nanmean(x2)
  
    v1 = np.nanmean(x1**2) - e1**2
    v2 = np.nanmean(x2**2) - e2**2

    v1 *= v1 > np.finfo(v1.dtype).eps
    v2 *= v2 > np.finfo(v2.dtype).eps
    if v1 == 0 and v2 == 0:
        return np.nan
    
    s2 = (v2*e1 + v1*e2) / (v1 + v2)  
    s = np.sqrt(np.abs(s2))
    if sign and s2 < 0: 
        s = -s
  
    return float(s)
