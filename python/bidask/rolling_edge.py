import pandas as pd
import numpy as np

def rolling_edge(
        df: pd.DataFrame, 
        window: int, 
        sign: bool = False,
        rolling_kwargs: dict = {},
        ) -> pd.Series:
    """
    Direct python implementation of the vectorized R code for rolling the `edge` estimate.
    Avoids the problem of chained means by expanding the required terms
    and computing probabilities, expectations, etc in a single rolling.mean call.
    
    Parameters
    ----------
    - `df` : pd.DataFrame
        DataFrame with columns 'open', 'high', 'low', 'close' (case-insensitive).
    - `window` : int
        Rolling window size.
    - `sign` : bool, default False
        Whether to return signed estimates.
    - `rolling_kwargs` : dict, optional
        Additional keyword arguments to pass to the pandas rolling function.
        See https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.rolling.html

    Returns
    -------
    pd.Series
        A pandas Series of rolling spread estimates. A value of 0.01 corresponds to a spread of 1%.
    """
    # Convert column names to lower case for consistency
    df = df.rename(columns=str.lower, inplace=False)
    o = np.log(df['open'])
    h = np.log(df['high'])
    l = np.log(df['low'])
    c = np.log(df['close'])
    m = (h + l)/2
    
    # Lagged values
    h1 = h.shift(1)
    l1 = l.shift(1)
    c1 = c.shift(1)
    m1 = m.shift(1)
    
    # Indicators
    tau = (h != l) | (l != c1)
    phi1 = (o != h) & (tau == 1)
    phi2 = (o != l) & (tau == 1)
    phi3 = (c1 != h1) & (tau == 1)
    phi4 = (c1 != l1) & (tau == 1)
    
    # Returns
    r1 = m - o
    r2 = o - m1
    r3 = m - c1
    r4 = c1 - m1
    r5 = o - c1

    # 1-based indexing for direct translation from R
    x = pd.DataFrame({
        1:  r1*r2,
        2:  r3*r4,
        3:  r1*r5,
        4:  r5*r4,
        5:  tau,
        6:  r1,
        7:  tau*r2,
        8:  r3,
        9:  tau*r4,
        10: r5,
        11: r1**2 * r2**2,
        12: r3**2 * r4**2,
        13: r1**2 * r5**2,
        14: r4**2 * r5**2,
        15: r1*r2*r3*r4,
        16: r1*r4*r5**2,
        17: tau*r2**2,
        18: tau*r4**2,
        19: tau*r5**2,
        20: tau*r1*r2**2,
        21: tau*r3*r4**2,
        22: tau*r1*r5**2,
        23: tau*r5*r4**2,
        24: tau*r1*r2*r4,
        25: tau*r2*r3*r4,
        26: tau*r2*r4,
        27: tau*r1*r4*r5,
        28: tau*r4*r5**2,
        29: tau*r4*r5,
        30: tau*r5,
        31: phi1,
        32: phi2,
        33: phi3,
        34: phi4
    }, index=df.index)
    
    # decided against x.iloc[1:].rolling as in the R code.
    # Keeps m lined up with o,h,l,c.
    m = x.rolling(window=window, **rolling_kwargs).mean()

    # Compute po and pc
    po = -8.0 / (m[31] + m[32])
    pc = -8.0 / (m[33] + m[34])

    e1 = (po/2.0)*(m[1] - (m[6]*m[7]/m[5])) + \
        (pc/2.0)*(m[2] - (m[8]*m[9]/m[5]))

    e2 = (po/2.0)*(m[3] - (m[6]*m[30]/m[5])) + \
        (pc/2.0)*(m[4] - (m[10]*m[9]/m[5]))
    
    v1 = (po**2/4.0 * (m[11] + (m[6]**2*m[17]/m[5]**2) - 2*m[20]*m[6]/m[5]) +
          pc**2/4.0 * (m[12] + (m[8]**2*m[18]/m[5]**2) - 2*m[21]*m[8]/m[5]) +
          (po*pc/2.0)*(m[15] - (m[24]*m[8]/m[5]) - (m[6]*m[25]/m[5]) + (m[6]*m[8]*m[26]/m[5]**2))
          - e1**2)

    v2 = (po**2/4.0 * (m[13] + (m[6]**2*m[19]/m[5]**2) - 2*m[22]*m[6]/m[5]) +
          pc**2/4.0 * (m[14] + (m[10]**2*m[18]/m[5]**2) - 2*m[23]*m[10]/m[5]) +
          (po*pc/2.0)*(m[16] - (m[27]*m[10]/m[5]) - (m[6]*m[28]/m[5]) + (m[6]*m[10]*m[29]/m[5]**2))
          - e2**2)

    S2 = (v2*e1 + v1*e2) / (v1 + v2)

    # Replace inf with NaN, as in R code
    S2 = S2.replace([np.inf, -np.inf], np.nan)

    # sign(S^2) is the same as sign(S)
    S = np.sign(S2)*np.sqrt(np.abs(S2))

    # Return signed estimate if requested
    if not sign:
        S = np.abs(S)

    return S