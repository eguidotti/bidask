using BidAsk
using CSV
using Test


@testset "edge" begin

    df = CSV.File(download("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv"))

    estimate = edge(df.:Open, df.:High, df.:Low, df.:Close)
    @test isapprox(0.0101849034905478, estimate)

    estimate = edge(df.:Open[1:10], df.:High[1:10], df.:Low[1:10], df.:Close[1:10], true)
    @test isapprox(-0.016889917516422, estimate)

    @test isnan(edge(
        [missing, missing, missing],
        [missing, missing, missing],
        [missing, missing, missing],
        [missing, missing, missing],
    ))

    @test isnan(edge(
        [18.21, 17.61, 17.61],
        [18.21, 17.61, 17.61],
        [17.61, 17.61, 17.61],
        [17.61, 17.61, 17.61]
    ))

end
