"""
R-parity rolling EDGE used by :func:`bidask.spread`. Port of ``EDGE`` in ``r/R/edge.R``.

The public ``edge``/``edge_rolling``/``edge_expanding`` functions are unchanged;
this module exists so ``spread(method="EDGE")`` follows R's ``width``/``na.rm``
semantics exactly, alongside the other estimators.
"""
import numpy as np
from . import _common as C


def EDGE(open, high, low, close, width, sign=False, na_rm=False):
    o, one_d = C.as_2d(open)
    h, _ = C.as_2d(high)
    l, _ = C.as_2d(low)
    c, _ = C.as_2d(close)
    C.check_same_shape(o, h, l, c)
    window = width if isinstance(width, C.Window) else C.Window(width, *o.shape)

    with C.quiet():
        o, h, l, c = C.log(o), C.log(h), C.log(l), C.log(c)
        m = (h + l) / 2
        h1, l1, c1, m1 = C.shift(h, 1), C.shift(l, 1), C.shift(c, 1), C.shift(m, 1)

        r1 = m - o
        r2 = o - m1
        r3 = m - c1
        r4 = c1 - m1
        r5 = o - c1

        tau = np.where(np.isnan(h) | np.isnan(l) | np.isnan(c1), np.nan,
                       C.r_or(C.ne(h, l), C.ne(l, c1)))
        po1 = tau * C.ne(o, h)
        po2 = tau * C.ne(o, l)
        pc1 = tau * C.ne(c1, h1)
        pc2 = tau * C.ne(c1, l1)

        r12, r15, r34, r45 = r1 * r2, r1 * r5, r3 * r4, r4 * r5
        tr1, tr2, tr4, tr5 = tau * r1, tau * r2, tau * r4, tau * r5

        cols = [
            r12, r34, r15, r45, tau, r1, tr2, r3, tr4, r5,
            r12 ** 2, r34 ** 2, r15 ** 2, r45 ** 2, r12 * r34, r15 * r45,
            tr2 * r2, tr4 * r4, tr5 * r5, tr2 * r12, tr4 * r34, tr5 * r15,
            tr4 * r45, tr4 * r12, tr2 * r34, tr2 * r4, tr1 * r45, tr5 * r45,
            tr4 * r5, tr5, po1, po2, pc1, pc2,
        ]
        for x in cols:
            x[:1] = np.nan
        # 1-based indexing to keep the formulas identical to the R source
        M = [None] + [C.rmean(x, window, 1, na_rm) for x in cols]

        pt = M[5]
        po = M[31] + M[32]
        pc = M[33] + M[34]

        nt = C.rsum(cols[4], window, 1, True)
        drop = (nt < 2) | (po == 0) | (pc == 0)
        for k in range(1, 35):
            M[k] = np.where(drop, np.nan, M[k])

        a1 = -4. / po
        a2 = -4. / pc
        a3 = M[6] / pt
        a4 = M[9] / pt
        a5 = M[8] / pt
        a6 = M[10] / pt
        a12 = 2 * a1 * a2
        a11 = a1 ** 2
        a22 = a2 ** 2
        a33 = a3 ** 2
        a55 = a5 ** 2
        a66 = a6 ** 2

        e1 = a1 * (M[1] - a3 * M[7]) + a2 * (M[2] - a4 * M[8])
        e2 = a1 * (M[3] - a3 * M[30]) + a2 * (M[4] - a4 * M[10])

        v1 = - e1 ** 2 + (
            a11 * (M[11] - 2 * a3 * M[20] + a33 * M[17]) +
            a22 * (M[12] - 2 * a5 * M[21] + a55 * M[18]) +
            a12 * (M[15] - a3 * M[25] - a5 * M[24] + a3 * a5 * M[26])
        )
        v2 = - e2 ** 2 + (
            a11 * (M[13] - 2 * a3 * M[22] + a33 * M[19]) +
            a22 * (M[14] - 2 * a6 * M[23] + a66 * M[18]) +
            a12 * (M[16] - a3 * M[28] - a6 * M[27] + a3 * a6 * M[29])
        )

        vt = v1 + v2
        s2 = np.where(~np.isnan(vt) & (vt > 0), (v2 * e1 + v1 * e2) / vt, (e1 + e2) / 2)
        s = np.sqrt(np.abs(s2))
        if sign:
            s = s * C.r_sign(s2)

    out = {"EDGE": s}
    if one_d:
        out = {k: v[:, 0] for k, v in out.items()}
    return out
