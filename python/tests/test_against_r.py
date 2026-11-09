"""
Cross-language parity: Python ``spread`` vs. R ``bidask::spread``.

Expected values in ``fixtures/expected.csv.gz`` are produced by
``fixtures/generate_fixtures.R`` from the R sources in ``r/R`` (see
``fixtures/VERSION.txt`` for the exact commit, R and data.table versions).
Every case runs all estimators on a fixed input for one combination of
``width`` x ``sign`` x ``na_rm``; Python must agree to 1e-10 and reproduce
R's missing values and errors exactly.
"""
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

from bidask import spread

FIX = Path(__file__).parent / "fixtures"
TOL = 1e-10
METHODS = ["EDGE", "AR", "AR2", "CS", "CS2", "ROLL",
           "OHL", "OHLC", "CHL", "CHLO", "OHL.CHL", "OHLC.CHLO"]

CASES = pd.read_csv(FIX / "cases.csv", keep_default_na=False)
EXPECTED = pd.read_csv(FIX / "expected.csv.gz", dtype=str, keep_default_na=False)
_INPUTS = {}


def load_input(name):
    if name not in _INPUTS:
        _INPUTS[name] = pd.read_csv(FIX / "inputs" / f"{name}.csv", dtype=str,
                                    keep_default_na=False).apply(parse)
    return _INPUTS[name].copy()


def parse(col):
    return pd.Series(col).replace({"NA": "nan", "NaN": "nan", "Inf": "inf", "-Inf": "-inf"}).astype(float)


def resolve_width(case, n):
    if case.width == "full":
        return None
    if case.width == "expanding":
        return np.arange(1, n + 1)
    w = [int(v) for v in case.width.split()]
    return w[0] if len(w) == 1 else w


def r_errors(case):
    if not case.errors:
        return {}
    return dict(part.split("=", 1) for part in case.errors.split(" | "))


def assert_close(actual, expected, label):
    actual = np.asarray(actual, dtype=float)
    expected = np.asarray(expected, dtype=float)
    assert actual.shape == expected.shape, label
    nan_a, nan_e = np.isnan(actual), np.isnan(expected)
    bad = np.flatnonzero(nan_a != nan_e)
    assert bad.size == 0, f"{label}: NaN mismatch at rows {bad[:10]} (py={actual[bad[:5]]}, r={expected[bad[:5]]})"
    inf = np.isinf(expected)
    np.testing.assert_array_equal(actual[inf], expected[inf], err_msg=label)
    ok = ~nan_e & ~inf
    np.testing.assert_allclose(actual[ok], expected[ok], rtol=TOL, atol=TOL, err_msg=label)


def test_fixture_metadata():
    meta = (FIX / "VERSION.txt").read_text()
    assert "bidask_r_version" in meta and "data.table" in meta
    assert len(CASES) > 300
    assert set(CASES.dataset) >= {"synth", "synth_miss", "msft_minute", "msft_daily"}


@pytest.mark.parametrize("case", list(CASES.itertuples(index=False)), ids=lambda c: c.case)
def test_spread_matches_r(case):
    x = load_input(case.dataset)
    width = resolve_width(case, len(x))
    errors = r_errors(case)
    expected = EXPECTED[EXPECTED.case == case.case]

    for m in METHODS:
        label = f"{case.case} {case.dataset} width={case.width} sign={case.sign} na_rm={case.na_rm} {m}"
        if m in errors:
            match = "non-negative" if "non-negative" in errors[m] else "must not exceed"
            with pytest.raises(ValueError, match=match):
                spread(x, width=width, method=m, sign=case.sign, na_rm=case.na_rm)
            continue
        out = spread(x, width=width, method=m, sign=case.sign, na_rm=case.na_rm)
        assert list(out.columns) == [m], label
        assert len(out) == case.nrow_out, label
        # R row names are 1-based positions of the rows kept
        np.testing.assert_array_equal(np.arange(len(x))[np.isin(x.index, out.index)] + 1
                                      if len(out) else [], expected.row.astype(int).to_numpy(),
                                      err_msg=label)
        assert_close(out[m].to_numpy(), parse(expected[m]).to_numpy(), label)


@pytest.mark.parametrize("sign", [False, True])
@pytest.mark.parametrize("na_rm", [False, True])
def test_all_methods_in_one_call_match_r(sign, na_rm):
    """Requesting several methods at once returns R's column order and values."""
    case = CASES[(CASES.dataset == "msft_minute") & (CASES.width_name == "w21")
                 & (CASES.sign == sign) & (CASES.na_rm == na_rm)].iloc[0]
    expected = EXPECTED[EXPECTED.case == case.case]
    order = ["ROLL", "OHLC.CHLO", "EDGE", "cs2", "AR", "chl"]
    out = spread(load_input("msft_minute"), width=21, method=order, sign=sign, na_rm=na_rm)
    assert list(out.columns) == [m.upper() for m in order]
    for m in out.columns:
        assert_close(out[m], parse(expected[m]), m)


@pytest.mark.parametrize("width", [None, 21, "expanding"])
@pytest.mark.parametrize("na_rm", [False, True])
def test_panel_matches_r_per_group(width, na_rm):
    """A long-format panel gives, per group, exactly R's single-series output."""
    names = ["synth", "synth_miss", "msft_minute", "msft_daily", "halted"]
    frames = []
    for name in names:
        df = load_input(name)
        df.insert(0, "id", name)
        frames.append(df)
    # interleave groups so the panel is not pre-sorted by id
    panel = pd.concat(frames, ignore_index=True)
    panel = panel.iloc[np.argsort(panel.groupby("id").cumcount().to_numpy(), kind="stable")]

    methods = [m for m in METHODS if not (width == "expanding" and m == "ROLL")]
    w = (panel.groupby("id").cumcount() + 1).to_numpy() if width == "expanding" else width
    out = spread(panel, width=w, method=methods, by="id", na_rm=na_rm)
    assert list(out.columns) == ["id"] + methods

    wname = {None: "full", 21: "w21", "expanding": "expanding"}[width]
    for name in names:
        case = CASES[(CASES.dataset == name) & (CASES.width_name == wname)
                     & (CASES.sign == False) & (CASES.na_rm == na_rm)].iloc[0]  # noqa: E712
        expected = EXPECTED[EXPECTED.case == case.case]
        got = out[out.id == name]
        assert len(got) == len(expected), name
        for m in methods:
            assert_close(got[m], parse(expected[m]), f"{name} {m}")
