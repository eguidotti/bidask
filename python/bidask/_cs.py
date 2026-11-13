"""
Corwin-Schultz (JF, 2012) high-low estimators. Port of ``r/R/cs.R``.
"""
import numpy as np
from . import _common as C

AVAILABLE = ("CS", "CS2")


def CS(high, low, close, width, method=("CS",), sign=False, na_rm=False):
    """
    Corwin & Schultz (2012) spread estimators, with the paper's overnight
    (close-to-open) adjustment: when the previous close lies outside today's
    high-low range, today's high and low are shifted by the gap.

    Same arguments as the R internal ``CS(high, low, close, width, method, sign, na.rm)``.

    * ``CS``: rolling mean of the two-day spread estimates, negative estimates
      kept. With ``sign=False`` the absolute value of the mean is returned.
    * ``CS2``: negative two-day estimates are set to zero before averaging.
      Always non-negative; ``sign`` has no effect, as in R.

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
        c1 = C.shift(c, 1)
        h1 = C.shift(h, 1)
        l1 = C.shift(l, 1)

        gap = np.maximum(0, c1 - h) + np.minimum(0, c1 - l)
        ah = h + gap
        al = l + gap

        b = (h - l) ** 2 + (h1 - l1) ** 2
        g = (np.maximum(ah, h1) - np.minimum(al, l1)) ** 2

        k = 3 - 2 * np.sqrt(2)
        a = (np.sqrt(2 * b) - np.sqrt(b)) / k - np.sqrt(g / k)
        s = 2 * (np.exp(a) - 1) / (1 + np.exp(a))

        out = {}
        if "CS" in method:
            cs = C.rmean(s, window, 1, na_rm)
            if not sign:
                cs = np.abs(cs)
            out["CS"] = cs
        if "CS2" in method:
            s = np.where(s < 0, 0.0, s)
            out["CS2"] = C.rmean(s, window, 1, na_rm)

    if one_d:
        out = {k: v[:, 0] for k, v in out.items()}
    return out
