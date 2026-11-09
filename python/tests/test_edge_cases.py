"""
Edge cases and invariants for the R-parity estimators: missing values,
single rows, constant prices, missing (halted) days, non-positive prices,
sign conventions, and panel vectorization.

Exact agreement with R on these inputs is covered by test_against_r.py (datasets
single_row, two_rows, constant, halted, nonpositive, open_at_high). The tests
here pin down the documented behavior directly.
"""
import time
import warnings

import numpy as np
import pandas as pd
import pytest

from bidask import spread
from bidask._ar import AR
from bidask._cs import CS
from bidask._roll import ROLL
from bidask._ohlc import OHLC
from bidask._edge import EDGE

METHODS = ["EDGE", "AR", "AR2", "CS", "CS2", "ROLL", "OHL", "OHLC", "CHL", "CHLO", "OHLC.CHLO"]
SIGNED = ["EDGE", "AR", "CS", "ROLL", "OHL", "OHLC", "CHL", "CHLO", "OHLC.CHLO"]
FLOORED = ["AR2", "CS2"]
FLAT_NAN = ["EDGE", "OHL", "OHLC", "CHL", "CHLO", "OHLC.CHLO"]
FLAT_ZERO = ["AR", "AR2", "CS", "CS2", "ROLL"]


def simulate(n=500, spread_=0.01, seed=0, trades=50, prob_missing=0.0):
    """Synthetic OHLC: efficient log-price random walk, trades at bid/ask."""
    rng = np.random.default_rng(seed)
    steps = rng.normal(0, 0.02 / np.sqrt(trades), size=(n, trades))
    p = np.exp(np.cumsum(steps.ravel()).reshape(n, trades))
    side = rng.choice([-1, 1], size=(n, trades))
    px = p * (1 + side * spread_ / 2)
    df = pd.DataFrame({"Open": px[:, 0], "High": px.max(1), "Low": px.min(1), "Close": px[:, -1]})
    if prob_missing:
        df[rng.random(n) < prob_missing] = np.nan
    return df


@pytest.fixture(autouse=True)
def no_warnings():
    with warnings.catch_warnings():
        warnings.simplefilter("error")
        yield


# --- recovers the true spread --------------------------------------------------

@pytest.mark.parametrize("method", ["EDGE", "AR", "OHLC", "CHLO", "ROLL"])
def test_recovers_simulated_spread(method):
    df = simulate(n=5000, spread_=0.01, trades=200)
    est = spread(df, method=method)[method].iloc[0]
    assert est == pytest.approx(0.01, abs=0.004)


# --- shapes ----------------------------------------------------------------------

def test_output_shapes_follow_r():
    df = simulate(100)
    assert spread(df, method=METHODS).shape == (1, len(METHODS))
    assert spread(df, method=METHODS).index.tolist() == [99]
    assert spread(df, width=21).index.tolist() == list(range(20, 100))
    assert spread(df, width=1).index.tolist() == list(range(1, 100))
    assert spread(df, width=np.arange(1, 101)).shape == (100, 1)
    assert spread(df, width=[3, 35, 100]).index.tolist() == [34, 99]


# --- single row / short samples ---------------------------------------------------

def test_single_row():
    df = simulate(1)
    assert spread(df, method=METHODS).empty
    out = spread(df, width=np.array([1]), method=FLAT_ZERO[:-1])
    assert out.isna().all().all()
    with pytest.raises(ValueError, match="must not exceed"):
        spread(df, width=3)


def test_two_rows():
    out = spread(simulate(2), method=METHODS).iloc[0]
    # one return pair: AR/CS defined, EDGE/OHLC need two informative periods, ROLL needs two returns
    assert out[["AR", "AR2", "CS", "CS2"]].notna().all()
    assert out[FLAT_NAN + ["ROLL"]].isna().all()


@pytest.mark.parametrize("method", METHODS)
def test_width_one_is_all_nan(method):
    assert spread(simulate(30), width=1, method=method)[method].isna().all()


def test_width_two_roll_is_nan_others_defined():
    out = spread(simulate(30), width=2, method=["ROLL", "AR", "CS"])
    assert out.ROLL.isna().all()
    assert out[["AR", "CS"]].notna().all().all()


# --- constant prices -----------------------------------------------------------

@pytest.mark.parametrize("width", [None, 10])
def test_constant_prices(width):
    df = pd.DataFrame({"Open": [50.0] * 30, "High": 50.0, "Low": 50.0, "Close": 50.0})
    out = spread(df, width=width, method=METHODS)
    assert out[FLAT_NAN].isna().all().all()
    assert (out[FLAT_ZERO] == 0).all().all()


# --- missing values / halted and zero-volume days ------------------------------

def test_nan_poisons_windows_unless_na_rm():
    df = simulate(200)
    df.iloc[100] = np.nan
    w = 21
    a = spread(df, width=w, method=METHODS)
    b = spread(df, width=w, method=METHODS, na_rm=True)
    # a width-w window at row t uses prices t-w+1..t, so rows 100..100+w-1 touch row 100
    hit = (a.index >= 100) & (a.index <= 100 + w - 1)
    assert a.loc[hit].isna().all().all()
    assert a.loc[~hit].notna().all().all()
    assert b.notna().all().all()


def test_missing_days_full_sample():
    df = simulate(400, prob_missing=0.05, seed=3)
    assert spread(df, method=METHODS).isna().all().all()
    est = spread(df, method=METHODS, na_rm=True)
    assert est.notna().all().all()


def test_zero_volume_bars_are_ignored_by_tau_estimators():
    """A bar flat at the previous close carries no information for EDGE/OHLC."""
    df = simulate(300, seed=4)
    flat = df.copy()
    rows = np.arange(50, 300, 25)
    for r in rows:  # halted: repeats the previous close
        flat.iloc[r] = flat.Close.iloc[r - 1]
    est = spread(flat, method=FLAT_NAN)
    assert est.notna().all().all()
    assert (est > 0).all().all()


def test_open_never_differs_from_high_and_low():
    """po == 0 => OHL/OHLC undefined; CHL still defined."""
    df = simulate(100)
    df["Open"] = df["High"]
    df["Low"] = df["High"]  # every bar is a point: o == h == l
    out = spread(df, method=["OHL", "OHLC", "CHL"])
    assert out[["OHL", "OHLC"]].isna().all().all()


# --- non-positive prices -------------------------------------------------------

@pytest.mark.parametrize("bad", [0.0, -1.0])
def test_non_positive_prices_do_not_raise(bad):
    df = simulate(60)
    df.loc[30, "Low"] = bad
    out = spread(df, width=10, method=METHODS)
    hit = (out.index >= 30) & (out.index <= 40)
    assert not np.isfinite(out.loc[hit, ["AR", "CS"]].to_numpy()).all()
    assert np.isfinite(out.loc[out.index > 41].to_numpy()).all()


# --- sign convention -----------------------------------------------------------

@pytest.mark.parametrize("width", [None, 5, 21])
def test_sign_convention(width):
    df = simulate(300, spread_=0.0005, seed=7)  # tiny spread: many negative s^2
    u = spread(df, width=width, method=METHODS, sign=False)
    s = spread(df, width=width, method=METHODS, sign=True)
    np.testing.assert_allclose(np.abs(s[SIGNED]), u[SIGNED], rtol=0, atol=0)
    assert (u.fillna(0) >= 0).all().all()
    pd.testing.assert_frame_equal(s[FLOORED], u[FLOORED])
    assert (u[FLOORED].fillna(0) >= 0).all().all()
    if width:
        assert (s[SIGNED] < 0).any().all(), "expected some negative estimates"


# --- invariance ----------------------------------------------------------------

def test_price_scale_invariance():
    df = simulate(200)
    a = spread(df, width=21, method=METHODS)
    b = spread(df * 37.5, width=21, method=METHODS)
    np.testing.assert_allclose(a, b, rtol=1e-8, atol=1e-12)


# --- inputs --------------------------------------------------------------------

def test_column_names_case_and_prefix():
    df = simulate(50)
    a = spread(df, method=METHODS)
    b = spread(df.rename(columns=lambda c: "MSFT." + c), method=METHODS)
    c = spread(df.rename(columns=str.upper), method=METHODS)
    pd.testing.assert_frame_equal(a, b)
    pd.testing.assert_frame_equal(a, c)


def test_method_validation_and_case():
    df = simulate(50)
    pd.testing.assert_frame_equal(spread(df, method="ar2"), spread(df, method="AR2"))
    with pytest.raises(ValueError, match="not available"):
        spread(df, method="FOO")
    with pytest.raises(ValueError, match="not available"):
        spread(df, method="OHLC.FOO")
    with pytest.raises(ValueError, match="missing column"):
        spread(df.drop(columns="Open"))


# --- panels --------------------------------------------------------------------

def test_wide_panel_matches_column_by_column():
    """(T, N) arrays are vectorized across columns and equal per-series results."""
    frames = [simulate(250, seed=s, prob_missing=0.02) for s in range(6)]
    o, h, l, c = (np.column_stack([f[k] for f in frames]) for k in ["Open", "High", "Low", "Close"])
    for na_rm in (False, True):
        for width in (21, np.arange(1, 251)):
            wide = {**EDGE(o, h, l, c, width, True, na_rm),
                    **AR(h, l, c, width, ["AR", "AR2"], True, na_rm),
                    **CS(h, l, c, width, ["CS", "CS2"], True, na_rm),
                    **OHLC(o, h, l, c, width, ["OHL", "CHLO", "OHLC.CHL"], True, na_rm)}
            if np.ndim(width) == 0:
                wide.update(ROLL(c, width, True, na_rm))
            for j, f in enumerate(frames):
                one = {**EDGE(f.Open, f.High, f.Low, f.Close, width, True, na_rm),
                       **AR(f.High, f.Low, f.Close, width, ["AR", "AR2"], True, na_rm),
                       **CS(f.High, f.Low, f.Close, width, ["CS", "CS2"], True, na_rm),
                       **OHLC(f.Open, f.High, f.Low, f.Close, width, ["OHL", "CHLO", "OHLC.CHL"], True, na_rm)}
                if np.ndim(width) == 0:
                    one.update(ROLL(f.Close, width, True, na_rm))
                for k, v in one.items():
                    np.testing.assert_array_equal(wide[k][:, j], v, err_msg=k)


def test_long_panel_unequal_lengths():
    a, b = simulate(120, seed=1), simulate(45, seed=2)
    panel = pd.concat([a.assign(id="a"), b.assign(id="b")], ignore_index=True)
    out = spread(panel, width=21, method=METHODS, by="id")
    pd.testing.assert_frame_equal(out[out.id == "a"][METHODS].reset_index(drop=True),
                                  spread(a, width=21, method=METHODS).reset_index(drop=True))
    pd.testing.assert_frame_equal(out[out.id == "b"][METHODS].reset_index(drop=True),
                                  spread(b, width=21, method=METHODS).reset_index(drop=True))
    full = spread(panel, method=METHODS, by="id")
    assert full.id.tolist() == ["a", "b"]
    # a group shorter than the window yields no rows instead of raising
    assert spread(panel, width=100, by="id").id.unique().tolist() == ["a"]
    with pytest.raises(NotImplementedError):
        spread(panel, width=[3, 30], by="id")


def test_large_panel_is_fast():
    rng = np.random.default_rng(0)
    T, N = 2520, 200  # ten years of daily data for 200 securities
    c = np.exp(np.cumsum(rng.normal(0, 0.01, (T, N)), axis=0))
    h, l, o = c * 1.01, c * 0.99, c * (1 + rng.normal(0, 0.002, (T, N)))
    start = time.perf_counter()
    for f in (lambda: AR(h, l, c, 21, ["AR", "AR2"]),
              lambda: CS(h, l, c, 21, ["CS", "CS2"]),
              lambda: ROLL(c, 21),
              lambda: OHLC(o, h, l, c, 21, ["OHLC", "CHLO"]),
              lambda: EDGE(o, h, l, c, 21)):
        f()
    assert time.perf_counter() - start < 30
