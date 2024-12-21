import numpy as np
import pandas as pd


def edge_expanding(df: pd.DataFrame, sign: bool = False, **kwargs) -> pd.Series:
    """
    Expanding Estimates of Bid-Ask Spreads from Open, High, Low, and Close Prices

    Implements an expanding window calculation of the efficient estimator of bid-ask spreads 
    from open, high, low, and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024):
    https://doi.org/10.1016/j.jfineco.2024.103916
        
    Parameters
    ----------
    - `df` : pd.DataFrame
        DataFrame with columns 'open', 'high', 'low', 'close' (case-insensitive).
    - `sign` : bool, default False
        Whether to return signed estimates.
    - `kwargs` : dict
        Additional keyword arguments to pass to the pandas expanding function.
        For more information about the expanding parameters, see 
        https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.expanding.html

    Returns
    -------
    pd.Series
        A pandas Series of expanding spread estimates. A value of 0.01 corresponds to a spread of 1%.
    """    
    # compute index of column names (case-insensitive)
    idx = {n: i for i, n in enumerate(df.columns.str.lower())}

    # compute log-prices
    o = np.log(df.iloc[:,idx['open']])
    h = np.log(df.iloc[:,idx['high']])
    l = np.log(df.iloc[:,idx['low']])
    c = np.log(df.iloc[:,idx['close']])
    m = (h + l) / 2.

    # shift log-prices by one period
    h1 = h.shift(1)
    l1 = l.shift(1)
    c1 = c.shift(1)
    m1 = m.shift(1)
    
    # decrement min_periods by one period to account for lagged prices
    for arg in ('min_periods',):
        if arg in kwargs and isinstance(kwargs[arg], (int, np.integer)):
            kwargs[arg] = max(0, kwargs[arg]-1)

    # compute tau 
    tau = (h != l) | (l != c1)
    
    # compute log-returns
    r1 = m-o
    r2 = o-m1
    r3 = m-c1
    r4 = c1-m1
    r5 = o-c1

    # compute auxiliary vectors
    r12 = r1*r2
    r15 = r1*r5
    r34 = r3*r4
    r45 = r4*r5
    tr1 = tau*r1
    tr2 = tau*r2
    tr4 = tau*r4
    tr5 = tau*r5
    
    # set up data frame to compute expanding means
    x = pd.DataFrame({
        1:  r12,
        2:  r34,
        3:  r15,
        4:  r45,
        5:  tau,
        6:  r1,
        7:  tr2,
        8:  r3,
        9:  tr4,
        10: r5,
        11: r12**2,
        12: r34**2,
        13: r15**2,
        14: r45**2,
        15: r12*r34,
        16: r15*r45,
        17: tr2*r2,
        18: tr4*r4,
        19: tr5*r5,
        20: tr2*r12,
        21: tr4*r34,
        22: tr5*r15,
        23: tr4*r45,
        24: tr4*r12,
        25: tr2*r34,
        26: tr2*r4,
        27: tr1*r45,
        28: tr5*r45,
        29: tr4*r5,
        30: tr5,
        31: tau & (o != h),
        32: tau & (o != l),
        33: tau & (c1 != h1),
        34: tau & (c1 != l1)
    }, index=df.index, dtype=float)
    
    # mask the first observation and compute expanding means
    x.iloc[0] = np.nan
    m = x.expanding(**kwargs).mean()

    # set to missing if there are less than 2 observations with tau=1
    m[x[5].expanding(**kwargs).sum() < 2] = np.nan

    # compute auxiliary values
    a1 = -4./(m[31]+m[32])
    a2 = -4./(m[33]+m[34])
    a3 = m[6]/m[5]
    a4 = m[9]/m[5]
    a5 = m[8]/m[5]
    a6 = m[10]/m[5]
    a12 = 2*a1*a2
    a11 = a1**2
    a22 = a2**2
    a33 = a3**2
    a55 = a5**2
    a66 = a6**2

    # compute expected values
    e1 = a1 * (m[1] - a3*m[7]) + a2 * (m[2] - a4*m[8])
    e2 = a1 * (m[3] - a3*m[30]) + a2 * (m[4] - a4*m[10])
    
    # compute variances
    v1 = - e1**2 + (
        a11 * (m[11] - 2*a3*m[20] + a33*m[17]) +
        a22 * (m[12] - 2*a5*m[21] + a55*m[18]) +
        a12 * (m[15] - a3*m[25] - a5*m[24] + a3*a5*m[26])
    )
    v2 = - e2**2 + (
        a11 * (m[13] - 2*a3*m[22] + a33*m[19]) + 
        a22 * (m[14] - 2*a6*m[23] + a66*m[18]) +
        a12 * (m[16] - a3*m[28] - a6*m[27] + a3*a6*m[29]) 
    )

    # compute square spread by using a (equally) weighted average if the total variance is (not) positive
    vt = v1 + v2
    s2 = pd.Series.where(cond=vt > 0, self=(v2 * e1 + v1 * e2) / vt, other=(e1 + e2) / 2.)

    # compute signed root
    s = np.sqrt(np.abs(s2))
    if sign:
        s *= np.sign(s2)

    # return the spread
    return s
