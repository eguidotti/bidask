"""
``spread()``: Python port of the R function ``bidask::spread``.
"""
import re
import numpy as np
import pandas as pd

from . import _common as C
from ._edge import EDGE
from ._ar import AR
from ._cs import CS
from ._roll import ROLL
from ._ohlc import OHLC

_PREFIX = re.compile(r"^(.*\b)(Open|High|Low|Close)$")


def _normalize_columns(cols):
    # R: tolower(gsub("^(.*\\b)(Open|High|Low|Close)$", "\\2", colnames(x)))
    return [_PREFIX.sub(r"\2", str(c)).lower() for c in cols]


def _estimate(o, h, l, c, window, method, sign, na_rm):
    """Run the requested estimators on (T, N) arrays. Mirrors the body of R's spread()."""
    s = {}
    todo = list(method)

    if "EDGE" in todo:
        s.update(EDGE(o, h, l, c, window, sign, na_rm))
        todo = [m for m in todo if m != "EDGE"]

    m = [x for x in todo if x in ("AR", "AR2")]
    if m:
        s.update(AR(h, l, c, window, m, sign, na_rm))
        todo = [x for x in todo if x not in m]

    m = [x for x in todo if x in ("CS", "CS2")]
    if m:
        s.update(CS(h, l, c, window, m, sign, na_rm))
        todo = [x for x in todo if x not in m]

    if "ROLL" in todo:
        s.update(ROLL(c, window, sign, na_rm))
        todo = [x for x in todo if x != "ROLL"]

    if todo:
        s.update(OHLC(o, h, l, c, window, todo, sign, na_rm))

    return s


def spread(x, width=None, method="EDGE", sign=False, na_rm=False, by=None):
    """
    Estimation of bid-ask spreads from open, high, low, and close prices.

    Port of ``bidask::spread(x, width = nrow(x), method = "EDGE", sign = FALSE, na.rm = FALSE)``.
    Arguments and results match the R function; ``na.rm`` is spelled ``na_rm``
    because ``na.rm`` is not a valid Python identifier.

    Parameters
    ----------
    x : pandas.DataFrame
        Columns named ``open``, ``high``, ``low``, ``close`` (case-insensitive;
        prefixes such as ``MSFT.Open`` are stripped, as in R). Rows must be
        sorted by time (within each group if ``by`` is given).
    width : int, array-like, or None
        * ``None`` (default): the full sample, one estimate (R: ``nrow(x)``).
        * int: rolling window of ``width`` rows.
        * array with one entry per row: the window width for each row
          (e.g. ``range(1, len(x) + 1)`` for an expanding window).
        * any other array: 1-based row endpoints. One estimate per endpoint
          after the first, computed on rows ``ep[k-1]..ep[k]``.
    method : str or list of str
        Any of ``EDGE``, ``AR``, ``AR2``, ``CS``, ``CS2``, ``ROLL``, ``OHL``,
        ``OHLC``, ``CHL``, ``CHLO``, or ``.``-joined combinations of the last
        four (e.g. ``OHLC.CHLO``). Case-insensitive.
    sign : bool
        Return signed estimates. See "Sign convention" below.
    na_rm : bool
        Ignore missing values inside each window.
    by : str, list of str, or None
        Panel support (Python only). Column(s) identifying each series in a
        long-format panel. Every group is estimated exactly as if R's
        ``spread`` were called on that group alone, in one vectorized pass.
        ``width`` must then be ``None``, an int, or a per-row array.

    Returns
    -------
    pandas.DataFrame
        One column per method, in the order requested, indexed like the rows
        of ``x`` that R keeps:

        * ``width=None``: the last row (of each group);
        * int ``width``: rows ``width`` onward (row 2 onward if ``width <= 1``);
        * per-row array: every row;
        * endpoints: the endpoint rows after the first.

        With ``by``, the group columns come first. A value of 0.01 means 1%.

    Sign convention
    ---------------
    ``EDGE``, ``AR``, ``CS``, ``ROLL`` and ``OHL``/``OHLC``/``CHL``/``CHLO``
    first estimate a squared spread ``s2``, which can be negative in finite
    samples. By default the result is ``sqrt(|s2|)``, which is never negative.
    With ``sign=True`` it is ``sign(s2) * sqrt(|s2|)``, so a negative value
    flags a negative squared-spread estimate. These estimates are kept, not
    set to zero, so averages across windows stay unbiased. (For ``CS`` the
    signed quantity is the mean of the two-day spread estimates, not its
    square.) ``AR2`` and ``CS2`` set negative per-period estimates to zero
    before averaging and are always ``>= 0``; ``sign`` does not affect them.

    Missing, halted and zero-volume periods
    ---------------------------------------
    * A missing price (NaN) poisons every window that contains it unless
      ``na_rm=True``. With ``na_rm=True`` each rolling mean is taken over the
      non-missing terms only, so drop halted days or set them to NaN. Do not
      forward-fill them.
    * A period with ``open == high == low == close`` equal to the previous
      close (a typical zero-volume or halted bar that repeats the last price)
      is non-informative. EDGE and OHL/OHLC/CHL/CHLO detect it through the
      indicator ``tau = (high != low) | (low != prev close)`` and leave it
      out of their probability terms. If fewer than two informative periods
      remain in a window, or the open (or close) never differs from the
      high/low, they return NaN. AR, CS and ROLL have no such filter: a flat
      bar enters as zero returns, which pulls their estimates toward zero.
    * Constant prices over a whole window give NaN for EDGE and
      OHL/OHLC/CHL/CHLO (no informative periods) and 0 for AR, AR2, CS, CS2
      and ROLL.
    * A price of 0 gives ``log(0) = -inf`` and a negative price gives NaN, as
      in R. No error or warning is raised. Windows containing such rows are
      NaN or infinite.
    * Windows too short for an estimator give NaN: every estimator needs one
      lagged price (ROLL needs two), so ``width=1`` is all NaN and ``width=2``
      is all NaN for ROLL. A one-row input with the default width returns an
      empty frame, because R drops the first row.
    * A fixed ``width`` greater than ``len(x) + 1`` raises ``ValueError``. R
      also errors here (an internal row-name length error); with ``by``, groups
      shorter than the window just contribute no rows.

    Examples
    --------
    >>> spread(df)                                   # full sample, EDGE
    >>> spread(df, width=21, method=["EDGE", "AR", "CS", "ROLL"])
    >>> spread(df, width=range(1, len(df) + 1))      # expanding
    >>> spread(df, width=[3, 35, 100])               # custom endpoints
    >>> spread(panel, width=21, method="AR", by="ticker")
    """
    if not isinstance(x, pd.DataFrame):
        raise TypeError("x must be a pandas DataFrame")

    method = [m.upper() for m in np.atleast_1d(method).tolist()]
    cols = _normalize_columns(x.columns)
    if len(set(cols)) != len(cols):
        raise ValueError("duplicate column names after normalization: %s" % cols)
    df = x.set_axis(cols, axis=1)
    missing = [k for k in ("open", "high", "low", "close") if k not in df.columns]
    if missing:
        raise ValueError("x is missing column(s): %s" % ", ".join(missing))

    if by is None:
        return _spread_single(df, x.index, width, method, sign, na_rm)
    return _spread_panel(x, df, by, width, method, sign, na_rm)


def _prices(df):
    return [pd.to_numeric(df[k], errors="coerce").to_numpy(dtype=np.float64)
            for k in ("open", "high", "low", "close")]


def _spread_single(df, index, width, method, sign, na_rm):
    nrow = len(df)
    if width is None:
        width = nrow
    o, h, l, c = _prices(df)
    window = C.Window(width, nrow, 1)
    if window.mode == "fixed" and window.width[0] - 1 > nrow:
        # R errors here too ("row names supplied are of the wrong length"):
        # rfun() writes NAs past the end of the series when width - 1 > nrow
        raise ValueError("width (%d) must not exceed nrow(x) + 1 (%d)"
                         % (window.width[0], nrow + 1))
    s = _estimate(o[:, None], h[:, None], l[:, None], c[:, None], window, method, sign, na_rm)
    out = pd.DataFrame({k: v[:, 0] for k, v in s.items()}, index=index)

    if window.mode == "fixed":
        w = int(window.width[0])
        out = out.iloc[max(1, w - 1):]
    elif window.mode == "endpoints":
        out = out.iloc[window.width[1:] - 1]
    return out[method]


def _spread_panel(x, df, by, width, method, sign, na_rm):
    by = [by] if isinstance(by, str) else list(by)
    keys = x[by]
    grp = keys.groupby(by, sort=False, dropna=False)
    col = grp.ngroup().to_numpy()
    pos = grp.cumcount().to_numpy()
    sizes = np.bincount(col)
    G = sizes.size
    T = int(sizes.max()) if G else 0

    # pad each group into its own column, aligned at row 0; trailing padding
    # never enters a right-aligned window of a real row
    arrays = []
    for a in _prices(df):
        wide = np.full((T, G), np.nan)
        wide[pos, col] = a
        arrays.append(wide)

    if width is None:
        window = C.Window(sizes, T, G, per_column=True)
        keep = pos == sizes[col] - 1
    else:
        w = np.asarray(width)
        if w.ndim == 0 or w.size == 1:
            w = int(w.reshape(-1)[0])
            window = C.Window(np.full(G, w), T, G, per_column=True)
            keep = pos >= max(1, w - 1)
        elif w.size == len(x):
            wide = np.zeros((T, G), dtype=np.int64)
            wide[pos, col] = w.astype(np.int64)
            real = np.zeros((T, G), dtype=bool)
            real[pos, col] = True
            window = _PanelAdaptive(wide, real)
            keep = np.ones(len(x), dtype=bool)
        else:
            raise NotImplementedError("endpoint widths are not supported with `by`")

    s = _estimate(*arrays, window, method, sign, na_rm)
    out = pd.DataFrame({k: v[pos, col] for k, v in s.items()}, index=x.index)
    out = pd.concat([keys, out[method]], axis=1)
    return out[keep]


class _PanelAdaptive(C.Window):
    """Per-row widths that differ across panel columns."""

    def __init__(self, widths, real):
        self.nrow, self.ncol = widths.shape
        self.mode = "adaptive"
        self.width = widths
        self.real = real

    def lengths(self, shift):
        # padding rows get an empty window so they never trip the n >= 0 check
        n = np.where(self.real, self.width - shift, 0)
        return n, ~self.real
