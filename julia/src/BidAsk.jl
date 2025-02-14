module BidAsk

using Statistics

"""
Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices

Implements the efficient estimator of bid-ask spreads from open, high, low, 
and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024):
https://doi.org/10.1016/j.jfineco.2024.103916

Parameters
----------
- `open`: AbstractVector of open prices
- `high`: AbstractVector of high prices
- `low`: AbstractVector of low prices
- `close`: AbstractVector of close prices
- `sign`: Whether to return signed estimates

Notes
-----
Prices must be sorted in ascending order of the timestamp.

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

    tau = ifelse.(ismissing.(h) .| ismissing.(l) .| ismissing.(c1),  missing,  (h .!= l) .| (l .!= c1))
    phi1 = collect(skipmissing(tau .* (o .!= h)))
    phi2 = collect(skipmissing(tau .* (o .!= l)))
    phi3 = collect(skipmissing(tau .* (c1 .!= h1)))
    phi4 = collect(skipmissing(tau .* (c1 .!= l1)))

    nt = sum(skipmissing(tau), init=0)
    if nt < 2 || length(phi1) == 0 || length(phi2) == 0 || length(phi3) == 0 || length(phi4) == 0
        return NaN
    end

    pt = nt / count(!ismissing, tau)
    po = mean(phi1) + mean(phi2)
    pc = mean(phi3) + mean(phi4)
    if po == 0 || pc == 0
        return NaN
    end

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

    vt = v1 + v2
    s2 = ifelse(vt > 0, (v2*e1 + v1*e2) / vt, (e1 + e2) / 2)

    s = sqrt(abs(s2))
    if sign && s2 < 0
        s = -s
    end

    return s
end

export 
edge

end # module
