import numpy as np


def edge(open: np.array, high: np.array, low: np.array, close: np.array, sign: bool = False) -> float:
    """
    Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

    Implements the efficient estimator of bid-ask spreads from open, high, low, 
    and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024):
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
    # check that the open, high, low, and close prices have the same length
    nobs = len(open)
    if len(high) != nobs or len(low) != nobs or len(close) != nobs:
        raise ValueError("Open, high, low, and close prices must have the same length")

    # return missing if there are less than 3 observations
    if nobs < 3:
        return np.nan

    # compute log-prices
    o = np.log(np.asarray(open))
    h = np.log(np.asarray(high))
    l = np.log(np.asarray(low))
    c = np.log(np.asarray(close))
    m = (h + l) / 2.

    # shift log-prices by one period
    h1, l1, c1, m1 = h[:-1], l[:-1], c[:-1], m[:-1]
    o, h, l, c, m = o[1:], h[1:], l[1:], c[1:], m[1:]

    # compute tau 
    # return missing if there are less than 2 observations with tau=1
    tau = np.logical_or(h != l, l != c1) 
    if np.nansum(tau) < 2:
        return np.nan
    
    # compute the probability that tau=1 
    # return missing if it is missing or zero
    pt = np.nanmean(tau)
    if np.isnan(pt) or pt == 0:
        return np.nan
    
    # compute the probability that tau=1 and the open differs from the high
    # compute the probability that tau=1 and the open differs from the low
    # compute their sum and return missing if it is missing or zero
    po = np.nanmean(np.logical_and(tau, o != h)) + np.nanmean(np.logical_and(tau, o != l))
    if np.isnan(po) or po == 0:
        return np.nan
    
    # compute the probability that tau=1 and the previous close differs from the previous high
    # compute the probability that tau=1 and the previous close differs from the previous low
    # compute their sum and return missing if it is missing or zero
    pc = np.nanmean(np.logical_and(tau, c1 != h1)) + np.nanmean(np.logical_and(tau, c1 != l1))
    if np.isnan(pc) or pc == 0:
        return np.nan

    # compute log-returns
    r1 = m - o
    r2 = o - m1
    r3 = m - c1
    r4 = c1 - m1
    r5 = o - c1
  
    # compute de-meaned log-returns
    d1 = r1 - tau * (np.nanmean(r1) / pt)
    d3 = r3 - tau * (np.nanmean(r3) / pt)
    d5 = r5 - tau * (np.nanmean(r5) / pt)
  
    # compute auxiliary vectors
    y1 = -4. / po * d1 
    y2 = -4. / pc * r4

    # compute input vectors
    x1 = y1 * r2 + y2 * d3 
    x2 = y1 * r5 + y2 * d5 
  
    # compute expected values
    e1 = np.nanmean(x1)
    e2 = np.nanmean(x2)
  
    # compute variances
    v1 = np.nanmean(x1**2) - e1**2
    v2 = np.nanmean(x2**2) - e2**2
    
    # compute square spread by using a (equally) weighted average if the total variance is (not) positive
    vt = v1 + v2
    s2 = (v2*e1 + v1*e2) / vt if vt > 0 else (e1 + e2) / 2.
    
    # compute signed root
    s = np.sqrt(np.abs(s2))
    if sign: 
        s *= np.sign(s2)
  
    # return the spread
    return float(s)
