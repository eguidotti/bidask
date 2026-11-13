"""
Abdi-Ranaldo (RFS, 2017) close-high-low estimators. Port of ``r/R/ar.R``.
"""
import numpy as np
from . import _common as C

AVAILABLE = ("AR", "AR2")


def AR(high, low, close, width, method=("AR",), sign=False, na_rm=False):
    """
    Abdi & Ranaldo (2017) spread estimators.

    Same arguments as the R internal ``AR(high, low, close, width, method, sign, na.rm)``.
    ``width`` is either a resolved :class:`bidask._common.Window` or any value
    accepted by R's ``width`` argument. Prices may be 1-D or ``(T, N)`` panels.

    * ``AR``: square root of the rolling mean of the per-period squared-spread
      proxy ``4 (c_{t-1} - eta_{t-1}) (c_{t-1} - eta_t)``. With ``sign=True``
      the root keeps the sign of the mean; otherwise its absolute value.
    * ``AR2``: per-period proxies are floored at zero, square-rooted, then
      averaged (the paper's "2-period" version). Always non-negative; ``sign``
      has no effect, as in R.

    Returns a dict ``{method: ndarray}`` with one value per input row.
    """
    method = [m.upper() for m in np.atleast_1d(method)]
    ko = [m for m in method if m not in AVAILABLE]
    if ko:
        raise ValueError("Method(s) '%s' not available. The available methods are '%s'."
                         % ("', '".join(ko), "', '".join(AVAILABLE)))

    h, one_d = C.as_2d(high)
    l, _ = C.as_2d(low)
    c, _ = C.as_2d(close)
    C.check_same_shape(h, l, c)
    window = width if isinstance(width, C.Window) else C.Window(width, *h.shape)

    with C.quiet():
        h, l, c = C.log(h), C.log(l), C.log(c)
        m2 = (h + l) / 2
        m1 = C.shift(m2, 1)
        c1 = C.shift(c, 1)
        s2 = 4 * (c1 - m1) * (c1 - m2)

        out = {}
        if "AR" in method:
            ar = C.rmean(s2, window, 1, na_rm)
            ar = C.r_sign(ar) * np.sqrt(np.abs(ar))
            if not sign:
                ar = np.abs(ar)
            out["AR"] = ar
        if "AR2" in method:
            s2 = np.where(s2 < 0, 0.0, s2)
            out["AR2"] = C.rmean(np.sqrt(s2), window, 1, na_rm)

    if one_d:
        out = {k: v[:, 0] for k, v in out.items()}
    return out
