"""
Shared windowing and validation helpers for the R-parity estimators.

Everything here mirrors ``r/R/utils.R`` (``rfun``, ``rsum``, ``rmean``) and the
``data.table`` primitives it relies on (``shift``, ``frollsum``, ``frollmean``).

All arrays are handled as 2-D ``(T, N)`` float arrays: ``T`` periods (rows,
sorted by time) and ``N`` independent series (panel columns). Windows always run
down axis 0, so a panel of ``N`` securities is processed in one vectorized pass
with no Python loop over rows or securities.
"""
import numpy as np


def as_2d(x):
    """Return ``x`` as a float64 ``(T, N)`` array and whether the input was 1-D."""
    a = np.asarray(x, dtype=np.float64)
    if a.ndim == 0:
        a = a.reshape(1, 1)
        return a, True
    if a.ndim == 1:
        return a[:, None], True
    if a.ndim == 2:
        return a, False
    raise ValueError("prices must be 1-D (one series) or 2-D (periods x series)")


def check_same_shape(*arrays):
    shape = arrays[0].shape
    for a in arrays[1:]:
        if a.shape != shape:
            raise ValueError("open, high, low, close must have the same length")


def log(x):
    """``log`` with R semantics: log(0) = -Inf, log(<0) = NaN, without warnings."""
    with np.errstate(divide="ignore", invalid="ignore"):
        return np.log(x)


def shift(x, k=1):
    """``data.table::shift(x, k)``: lag along axis 0, filling with NaN."""
    out = np.full_like(x, np.nan)
    if k < x.shape[0]:
        out[k:] = x[: x.shape[0] - k]
    return out


def ne(a, b):
    """R's ``a != b``: NA if either operand is NA, else 1.0/0.0."""
    return np.where(np.isnan(a) | np.isnan(b), np.nan, (a != b).astype(np.float64))


def r_or(a, b):
    """R's three-valued ``a | b`` on 1.0/0.0/NaN arrays."""
    out = np.where(np.isnan(a) | np.isnan(b), np.nan, np.maximum(a, b))
    out[(a == 1) | (b == 1)] = 1.0
    return out


def r_sign(x):
    """R's ``sign()``: NaN-propagating, sign(0) = 0."""
    return np.sign(x)


# ---------------------------------------------------------------------------
# Window specification
# ---------------------------------------------------------------------------

class Window:
    """
    Resolved window specification, equivalent to the ``width`` argument in R.

    ``width`` may be:

    * an int: fixed rolling window (``nw == 1`` in R);
    * a vector with one entry per row: per-row (adaptive) window widths;
    * any other vector: 1-based endpoints. Each endpoint ``e_k`` gets one
      estimate computed on prices ``e_{k-1}..e_k``.

    For panels, ``width`` may also be a length-``N`` array of ints
    (``per_column=True``): a fixed window per series, used to reproduce R's
    full-sample default (``width = nrow(x)``) one group at a time.
    """

    def __init__(self, width, nrow, ncol=1, per_column=False):
        self.nrow = nrow
        self.ncol = ncol
        if per_column:
            w = np.asarray(width, dtype=np.int64).reshape(-1)
            if w.shape[0] != ncol:
                raise ValueError("per-column width must have one entry per series")
            self.mode = "fixed"
            self.width = w
            return
        w = np.asarray(width)
        if w.ndim == 0 or w.size == 1:
            self.mode = "fixed"
            self.width = np.full(ncol, int(w.reshape(-1)[0]), dtype=np.int64)
        elif w.size == nrow:
            self.mode = "adaptive"
            self.width = w.astype(np.int64).reshape(-1)
        else:
            self.mode = "endpoints"
            self.width = w.astype(np.int64).reshape(-1)
        if self.mode != "fixed" and np.any(np.isnan(np.asarray(width, dtype=float))):
            raise ValueError("width must not contain missing values")

    def lengths(self, shift):
        """Window length per (row, column) and a mask of rows forced to NaN.

        Mirrors ``rfun`` in ``r/R/utils.R``.
        """
        T, N = self.nrow, self.ncol
        if self.mode == "fixed":
            n = np.broadcast_to(self.width - shift, (T, N)).copy()
            rows = np.arange(T)[:, None]
            # R: if (nw == 1 && n < 1) everything is NA
            # R: if (nw == 1 && width > 1) the first width-1 rows are NA
            mask = (n < 1) | (rows < (self.width[None, :] - 1))
            return n, mask
        if self.mode == "adaptive":
            n = np.broadcast_to((self.width - shift)[:, None], (T, N)).copy()
            return n, np.zeros((T, N), dtype=bool)
        # endpoints
        n = np.zeros(T, dtype=np.int64)
        ep = self.width
        if ep.size > 1:
            n[ep[1:] - 1] = np.diff(np.maximum(1, ep))
        n = np.broadcast_to(n[:, None], (T, N)).copy()
        return n, np.zeros((T, N), dtype=bool)


# ---------------------------------------------------------------------------
# Rolling sum / mean (data.table::frollsum / frollmean, align = "right")
# ---------------------------------------------------------------------------

def _csum(a):
    T, N = a.shape
    out = np.zeros((T + 1, N), dtype=a.dtype)
    np.cumsum(a, axis=0, out=out[1:])
    return out


def _wsum(C, start, end):
    return np.take_along_axis(C, end, axis=0) - np.take_along_axis(C, start, axis=0)


def _block_sum(src, k):
    """Exact-as-direct sums of every length-``k`` window down axis 0.

    Rows are split into blocks of ``k``; a window then spans at most two
    blocks, so its sum is the suffix sum of the first block plus the prefix sum
    of the second (or a single block prefix when aligned). Rounding stays local
    to the window, as with direct summation (a one-row window returns the row
    itself), in O(T * N) time. Returns rows ``k-1 .. T-1``.
    """
    T, N = src.shape
    P = -(-T // k) * k
    pad = np.zeros((P, N))
    pad[:T] = src
    blocks = pad.reshape(P // k, k, N)
    pre = np.cumsum(blocks, axis=1).reshape(P, N)
    suf = np.cumsum(blocks[:, ::-1], axis=1)[:, ::-1].reshape(P, N)
    e = np.arange(k - 1, T)
    st = e - k + 1
    aligned = (st % k == 0)[:, None]
    return np.where(aligned, pre[e], suf[st] + pre[e])


def _fixed_counts(a, k):
    """Integer window counts of a boolean array for fixed width ``k`` (rows k-1..T-1)."""
    c = _csum(a.astype(np.int64))
    return c[k:] - c[: c.shape[0] - k]


def _roll_fixed(fin, isnan, pinf, ninf, widths):
    """Window sums and counts for a fixed width per column.

    Loops only over the distinct widths (one, except for panels whose groups
    use their own full-sample width), never over rows.
    """
    T, N = fin.shape
    s = np.zeros((T, N))
    k_nan = np.zeros((T, N), np.int64)
    k_pinf = np.zeros((T, N), np.int64) if pinf is not None else None
    k_ninf = np.zeros((T, N), np.int64) if ninf is not None else None
    for k in np.unique(widths):
        k = int(k)
        if k < 1 or k > T:
            continue  # masked or not enough rows: handled by the caller
        cols = np.flatnonzero(widths == k)
        sel = slice(None) if cols.size == N else cols
        s[k - 1:, sel] = _block_sum(fin[:, sel], k)
        k_nan[k - 1:, sel] = _fixed_counts(isnan[:, sel], k)
        if pinf is not None:
            k_pinf[k - 1:, sel] = _fixed_counts(pinf[:, sel], k)
            k_ninf[k - 1:, sel] = _fixed_counts(ninf[:, sel], k)
    return s, k_nan, k_pinf, k_ninf


def roll(x, window, shift, na_rm, kind):
    """
    Right-aligned rolling ``sum`` or ``mean`` of each column of ``x`` with the
    window lengths given by ``window.lengths(shift)``.

    Semantics follow ``data.table::frollsum``/``frollmean`` (``fill = NA``):

    * rows with fewer than ``n`` preceding observations are NaN;
    * ``na_rm=False``: any NaN in the window gives NaN;
    * ``na_rm=True``: NaNs are dropped; an all-NaN window gives NaN for the
      mean and 0 for the sum;
    * ``+Inf``/``-Inf`` propagate as in a plain sum (both present -> NaN).

    Cost is O(T * N) for any window length. Fixed windows use block-local
    prefix/suffix sums (rounding local to each window); per-row windows
    (adaptive/endpoints) use cumulative sums, like data.table's adaptive mode.
    """
    x = np.asarray(x, dtype=np.float64)
    if x.ndim == 1:
        x = x[:, None]
    T, N = x.shape
    n, mask = window.lengths(shift)
    if window.mode != "fixed" and np.any(n < 0):
        # data.table::froll* error for adaptive windows
        raise ValueError("'n' must be non-negative integer values (>= 0)")

    isnan = np.isnan(x)
    isinf = np.isinf(x)
    has_inf = bool(isinf.any())
    pinf = (x == np.inf) if has_inf else None
    ninf = (x == -np.inf) if has_inf else None
    fin = np.where(isnan | isinf, 0.0, x) if (has_inf or isnan.any()) else x

    if window.mode == "fixed":
        s, k_nan, k_pinf, k_ninf = _roll_fixed(fin, isnan, pinf, ninf, n[0])
        ok = np.arange(T)[:, None] >= (n[0][None, :] - 1)
    else:
        end = np.broadcast_to(np.arange(1, T + 1)[:, None], (T, N))
        start = end - n
        # rows whose window reaches before the start of the sample are NA (fill)
        ok = start >= 0
        startc = np.clip(start, 0, T)
        s = _wsum(_csum(fin), startc, end)
        k_nan = _wsum(_csum(isnan.astype(np.int64)), startc, end)
        if has_inf:
            k_pinf = _wsum(_csum(pinf.astype(np.int64)), startc, end)
            k_ninf = _wsum(_csum(ninf.astype(np.int64)), startc, end)

    with np.errstate(invalid="ignore", divide="ignore"):
        if has_inf:
            s = np.where(k_pinf > 0, np.inf, s)
            s = np.where(k_ninf > 0, -np.inf, s)
            s = np.where((k_pinf > 0) & (k_ninf > 0), np.nan, s)

        if na_rm:
            cnt = n - k_nan
            if kind == "mean":
                out = np.where(cnt > 0, s / np.where(cnt > 0, cnt, 1), np.nan)
            else:
                out = s
        else:
            if kind == "mean":
                out = np.where(n > 0, s / np.where(n > 0, n, 1), np.nan)
            else:
                out = s
            out = np.where(k_nan > 0, np.nan, out)

    out = np.where(ok, out, np.nan)
    out[mask] = np.nan
    return out


def rmean(x, window, shift, na_rm):
    return roll(x, window, shift, na_rm, "mean")


def rsum(x, window, shift, na_rm):
    return roll(x, window, shift, na_rm, "sum")


def quiet():
    """Silence numpy floating-point warnings; R computes these cases silently."""
    return np.errstate(all="ignore")
