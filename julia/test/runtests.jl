using BidAsk
using CSV
using DataFrames
using Test

@testset "edge()" begin
    df = CSV.File("../../pseudocode/ohlc.csv")
    estimate = edge(df.:Open, df.:High, df.:Low, df.:Close)
    println(estimate)
    @test isapprox(0.00010101064175748407, estimate)
end