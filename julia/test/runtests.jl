using BidAsk
using CSV
using DataFrames
using Test

@testset "edge()" begin
    df = CSV.File("../../pseudocode/ohlc.csv")
    estimate = edge(df.:Open, df.:High, df.:Low, df.:Close)
    @test isapprox(0.0100504050543988, estimate)
end
