module BidAsk

using Statistics

"""
Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements an efficient estimator of bid-ask spreads from open, high, low, and close prices 
as described in Ardia, Guidotti, & Kroencke (2024) -> https://doi.org/10.1016/j.jfineco.2024.103916

Prices must be sorted in ascending order of the timestamp.

Parameters
----------
- `open`: AbstractVector of open prices
- `high`: AbstractVector of high prices
- `low`: AbstractVector of low prices
- `close`: AbstractVector of close prices
- `sign`: whether signed estimates should be returned

Returns
-------
The spread estimate. A value of 0.01 corresponds to a spread of 1%.

"""
function edge(open::AbstractVector, high::AbstractVector, low::AbstractVector, close::AbstractVector, sign::Bool = false)
    
    o = log.(open)
    h = log.(high)
    l = log.(low)
    c = log.(close)
    m = (h .+ l) ./ 2.0

    h1 = h[1:end-1]
    l1 = l[1:end-1]
    c1 = c[1:end-1]
    m1 = m[1:end-1]

    o = o[2:end]
    h = h[2:end]
    l = l[2:end]
    c = c[2:end]
    m = m[2:end]

    tau = (h .!= l) .| (l .!= c1) 
    phi1 = (o .!= h) .& tau
    phi2 = (o .!= l) .& tau
    phi3 = (c1 .!= h1) .& tau
    phi4 = (c1 .!= l1) .& tau

    pt = mean(skipmissing(tau))
    po = mean(skipmissing(phi1)) + mean(skipmissing(phi2))
    pc = mean(skipmissing(phi3)) + mean(skipmissing(phi4))

    r1 = m .- o
    r2 = o .- m1
    r3 = m .- c1
    r4 = c1 .- m1
    r5 = o .- c1

    d1 = r1 .- tau .* mean(skipmissing(r1)) ./ pt
    d3 = r3 .- tau .* mean(skipmissing(r3)) ./ pt
    d5 = r5 .- tau .* mean(skipmissing(r5)) ./ pt

    x1 = - 4.0 ./ po .* d1 .* r2 .- 4.0 ./ pc .* d3 .* r4 
    x2 = - 4.0 ./ po .* d1 .* r5 .- 4.0 ./ pc .* d5 .* r4 
    
    e1 = mean(skipmissing(x1))
    e2 = mean(skipmissing(x2))

    v1 = mean(skipmissing(x1 .* x1)) - e1 * e1
    v2 = mean(skipmissing(x2 .* x2)) - e2 * e2

    s2 = (v2 * e1 + v1 * e2) / (v1 + v2)

    s = sqrt(abs(s2))
    if sign & (s2 < 0)
        s = -s
    end

    return s
end

export 
edge

end # module
