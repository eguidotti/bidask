import pytest
import numpy as np
import pandas as pd
from bidask import edge


def test_edge():

    df = pd.read_csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")

    estimate = edge(df.Open, df.High, df.Low, df.Close)
    assert estimate == pytest.approx(0.0101849034905478)
  
    estimate = edge(df.Open[0:10], df.High[0:10], df.Low[0:10], df.Close[0:10], True)
    assert estimate == pytest.approx(-0.016889917516422)

    assert np.isnan(edge(
        [18.21, 17.61, 17.61],
        [18.21, 17.61, 17.61],
        [17.61, 17.61, 17.61],
        [17.61, 17.61, 17.61]
    ))
