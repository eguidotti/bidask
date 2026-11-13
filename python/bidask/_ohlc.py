"""
Generalized OHL / OHLC / CHL / CHLO estimators of Ardia, Guidotti & Kroencke
(JFE, 2024). Port of ``r/R/ohlc.R``.
"""
import numpy as np
from . import _common as C

AVAILABLE = ("OHL", "OHLC", "CHL", "CHLO")


def OHLC(open, high, low, close, width, method=("OHLC",), sign=False, na_rm=False):
    """
    Generalized estimators from Ardia, Guidotti & Kroencke (2024).

    Same arguments as the R internal ``OHLC(open, high, low, close, width, method, sign, na.rm)``.
    ``method`` entries are ``OHL``, ``OHLC``, ``CHL``, ``CHLO`` or any
    ``.``-joined combination (e.g. ``OHLC.CHLO``), which averages the squared
    spreads of the components before taking the root.

    Returns a dict ``{method: ndarray}`` with one value per input row.
    """
    method = [m.upper() for m in np.atleast_1d(method)]
    split = [m.split(".") for m in method]
    unique = {p for parts in split for p in parts}
    ko = sorted(unique - set(AVAILABLE), key=[p for parts in split for p in parts].index)
    if ko:
        raise ValueError(
            "Method(s) '%s' not available. The available methods include '%s', "
            "or any combination of them, e.g. 'OHLC.CHLO'."
            % ("', '".join(ko), "', '".join(AVAILABLE)))

    o, one_d = C.as_2d(open)
    h, _ = C.as_2d(high)
    l, _ = C.as_2d(low)
    c, _ = C.as_2d(close)
    C.check_same_shape(o, h, l, c)
    window = width if isinstance(width, C.Window) else C.Window(width, *o.shape)

    with C.quiet():
        o, h, l, c = C.log(o), C.log(h), C.log(l), C.log(c)
        m = (h + l) / 2
        c1 = C.shift(c, 1)
        h1 = C.shift(h, 1)
        l1 = C.shift(l, 1)
        m1 = C.shift(m, 1)

        # R: ifelse(is.na(h) | is.na(l), NA, h != l | l != c1) -- three-valued OR
        tau = np.where(np.isnan(h) | np.isnan(l), np.nan, C.r_or(C.ne(h, l), C.ne(l, c1)))
        tau[:1] = np.nan

        pt = C.rmean(tau, window, 1, na_rm)
        nt = C.rsum(tau, window, 1, True)

        po = pc = None
        if unique & {"OHL", "OHLC"}:
            po = (C.rmean(tau * C.ne(o, h), window, 1, na_rm)
                  + C.rmean(tau * C.ne(o, l), window, 1, na_rm))
        if unique & {"CHL", "CHLO"}:
            pc = (C.rmean(tau * C.ne(c1, h1), window, 1, na_rm)
                  + C.rmean(tau * C.ne(c1, l1), window, 1, na_rm))

        def s2(r1, r2, pi):
            cols = [r1 * r2, r1, tau * r2]
            means = []
            drop = (nt < 2) | (pi == 0)  # NaN comparisons are False, like which()
            for x in cols:
                x = x.copy()
                x[:1] = np.nan
                mx = C.rmean(x, window, 1, na_rm)
                mx[drop] = np.nan
                means.append(mx)
            return -8 / pi * (means[0] - (means[1] * means[2]) / pt)

        est = {}
        if "OHL" in unique:
            est["OHL"] = s2(m - o, o - m1, po)
        if "OHLC" in unique:
            est["OHLC"] = s2(m - o, o - c1, po)
        if "CHL" in unique:
            est["CHL"] = s2(m - c1, c1 - m1, pc)
        if "CHLO" in unique:
            est["CHLO"] = s2(o - c1, c1 - m1, pc)

        out = {}
        for name, parts in zip(method, split):
            sq = sum(est[p] for p in parts) / len(parts)
            s = np.sqrt(np.abs(sq))
            if sign:
                s = s * C.r_sign(sq)
            out[name] = s

    if one_d:
        out = {k: v[:, 0] for k, v in out.items()}
    return out
