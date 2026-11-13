"""
Roll (JF, 1984) covariance estimator. Port of ``r/R/roll.R``.
"""
import numpy as np
from . import _common as C


def ROLL(close, width, sign=False, na_rm=False):
    """
    Roll (1984) estimator: ``2 sqrt(-cov(r_t, r_{t-1}))`` on log close-to-close
    returns, using the unbiased (n-1) covariance over the window.

    Same arguments as the R internal ``ROLL(close, width, sign, na.rm)``.
    When the autocovariance is positive the squared spread is negative; the
    result is ``sqrt(|s^2|)``, carrying the sign of ``s^2`` when ``sign=True``.

    Returns ``{"ROLL": ndarray}`` with one value per input row.
    """
    c, one_d = C.as_2d(close)
    window = width if isinstance(width, C.Window) else C.Window(width, *c.shape)

    with C.quiet():
        c = C.log(c)
        c1 = C.shift(c, 1)
        c2 = C.shift(c, 2)
        r1 = c - c1
        r2 = c1 - c2

        m1 = C.rmean(r1, window, 2, na_rm)
        m2 = C.rmean(r2, window, 2, na_rm)
        m3 = C.rmean(r1 * r2, window, 2, na_rm)
        n = C.rsum((~np.isnan(r2)).astype(np.float64), window, 2, na_rm)

        s2 = -4 * n / (n - 1) * (m3 - m1 * m2)
        s = C.r_sign(s2) * np.sqrt(np.abs(s2))
        if not sign:
            s = np.abs(s)

    out = {"ROLL": s}
    if one_d:
        out = {k: v[:, 0] for k, v in out.items()}
    return out
