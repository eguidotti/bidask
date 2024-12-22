import pandas as pd
from .edge_rolling import edge_rolling


def edge_expanding(df: pd.DataFrame, min_periods: int = 1, sign: bool = False) -> pd.Series:
    """
    Expanding Estimates of Bid-Ask Spreads from Open, High, Low, and Close Prices

    Implements an expanding window calculation of the efficient estimator of bid-ask spreads 
    from open, high, low, and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024):
    https://doi.org/10.1016/j.jfineco.2024.103916
        
    Parameters
    ----------
    - `df` : pd.DataFrame
        DataFrame with columns 'open', 'high', 'low', 'close' (case-insensitive).
    - `min_periods` : int
        Minimum number of observations in window required to have a value; otherwise, result is `np.nan`.
    - `sign` : bool, default False
        Whether to return signed estimates.

    Returns
    -------
    pd.Series
        A pandas Series of expanding spread estimates. A value of 0.01 corresponds to a spread of 1%.
    """    
    return edge_rolling(df=df, window=len(df), min_periods=min_periods, sign=sign)
