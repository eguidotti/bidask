import numpy as np
import pandas as pd


def edge_rolling(df: pd.DataFrame, window: int, sign: bool = False, **kwargs) -> pd.Series:
    """
    Rolling Estimates of Bid-Ask Spreads from Open, High, Low, and Close Prices

    Implements a rolling window calculation of the efficient estimator of bid-ask spreads 
    from open, high, low, and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024):
    https://doi.org/10.1016/j.jfineco.2024.103916
        
    Parameters
    ----------
    - `df` : pd.DataFrame
        DataFrame with columns 'open', 'high', 'low', 'close' (case-insensitive).
    - `window` : int, timedelta, str, offset, or BaseIndexer subclass
        Size of the moving window. For more information about this parameter, see
        https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.rolling.html
    - `sign` : bool, default False
        Whether to return signed estimates.
    - `kwargs` : dict, optional
        Additional keyword arguments to pass to the pandas rolling function.
        For more information about the rolling parameters, see 
        https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.rolling.html

    Returns
    -------
    pd.Series
        A pandas Series of rolling spread estimates. A value of 0.01 corresponds to a spread of 1%.
    """    
    # compute log-prices
    df = df.rename(columns=str.lower, inplace=False)
    o = np.log(df['open'])
    h = np.log(df['high'])
    l = np.log(df['low'])
    c = np.log(df['close'])
    m = (h + l) / 2.

    # shift log-prices by one period
    h1 = h.shift(1)
    l1 = l.shift(1)
    c1 = c.shift(1)
    m1 = m.shift(1)
    
    # compute log-returns
    r1 = m - o
    r2 = o - m1
    r3 = m - c1
    r4 = c1 - m1
    r5 = o - c1

    # compute indicator variables
    tau = np.where(np.isnan(h) | np.isnan(l) | np.isnan(c1), np.nan, (h != l) | (l != c1))
    po1 = tau * np.where(np.isnan(o) | np.isnan(h), np.nan, o != h)
    po2 = tau * np.where(np.isnan(o) | np.isnan(l), np.nan, o != l)
    pc1 = tau * np.where(np.isnan(c1) | np.isnan(h1), np.nan, c1 != h1)
    pc2 = tau * np.where(np.isnan(c1) | np.isnan(l1), np.nan, c1 != l1)
    
    # set up data frame for rolling means
    r12 = r1 * r2
    r15 = r1 * r5
    r34 = r3 * r4
    r45 = r4 * r5
    tr1 = tau * r1
    tr2 = tau * r2
    tr4 = tau * r4
    tr5 = tau * r5    
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
        11: r12 ** 2,
        12: r34 ** 2,
        13: r15 ** 2,
        14: r45 ** 2,
        15: r12 * r34,
        16: r15 * r45,
        17: tr2 * r2,
        18: tr4 * r4,
        19: tr5 * r5,
        20: tr2 * r12,
        21: tr4 * r34,
        22: tr5 * r15,
        23: tr4 * r45,
        24: tr4 * r12,
        25: tr2 * r34,
        26: tr2 * r4,
        27: tr1 * r45,
        28: tr5 * r45,
        29: tr4 * r5,
        30: tr5,
        31: po1,
        32: po2,
        33: pc1,
        34: pc2
    }, index=df.index)
    
    # mask the first observation and decrement window and min_periods to account for lagged prices
    x.iloc[0] = np.nan
    if isinstance(window, (int, np.integer)):
        window = max(0, window - 1)
    if 'min_periods' in kwargs and isinstance(kwargs['min_periods'], (int, np.integer)):
        kwargs['min_periods'] = max(0, kwargs['min_periods'] - 1)

    # compute rolling means
    m = x.rolling(window=window, **kwargs).mean()

    # compute probabilities
    pt = m[5]
    po = m[31] + m[32]
    pc = m[33] + m[34]

    # set to missing if there are less than two periods with tau=1
    # or po or pc is zero
    nt = x[5].rolling(window=window, **kwargs).sum()
    m[(nt < 2) | (po == 0) | (pc == 0)] = np.nan

    # compute input vectors
    a1 = -4. / po
    a2 = -4. / pc
    a3 = m[6] / pt
    a4 = m[9] / pt
    a5 = m[8] / pt
    a6 = m[10] / pt
    a12 = 2 * a1 * a2
    a11 = a1 ** 2
    a22 = a2 ** 2
    a33 = a3 ** 2
    a55 = a5 ** 2
    a66 = a6 ** 2

    # compute expectations
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

    # compute square spread by using a (equally) weighted 
    # average if the total variance is (not) positive
    vt = v1 + v2
    s2 = pd.Series.where(
        cond=vt > 0, 
        self=(v2*e1 + v1*e2) / vt, 
        other=(e1 + e2) / 2.
    )

    # compute signed root
    s = np.sqrt(np.abs(s2))
    if sign:
        s *= np.sign(s2)

    # return the spread
    return s
