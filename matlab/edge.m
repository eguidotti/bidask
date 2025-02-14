function s = edge(open, high, low, close, sign)
    % Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices
    %
    % Implements the efficient estimator of bid-ask spreads from open, high, low, 
    % and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024):
    % https://doi.org/10.1016/j.jfineco.2024.103916
    %
    % Parameters
    % ----------
    % - `open`: vector of open prices with size Tx1
    % - `high`: vector of high prices with size Tx1
    % - `low`: vector of low prices with size Tx1
    % - `close`: vector of close prices with size Tx1
    % - `sign`: boolean value indicating whether to return signed estimates
    %
    % Notes
    % -----
    % Prices must be sorted in ascending order of the timestamp.
    %
    % Returns
    % -------
    % The spread estimate. A value of 0.01 corresponds to a spread of 1%.
    %
    if nargin < 5
        sign = false;
    end

    p = log([open, high, low, close]);

    o = p(:,1); 
    h = p(:,2); 
    l = p(:,3);
    c = p(:,4);
    m = (h + l) / 2;

    h1 = h(1:end-1,:);
    l1 = l(1:end-1,:);
    c1 = c(1:end-1,:);
    m1 = m(1:end-1,:);

    o = o(2:end,:);
    h = h(2:end,:);
    l = l(2:end,:);
    c = c(2:end,:);
    m = m(2:end,:);

    tau = NaN(size(c));
    idx = ~(isnan(h) | isnan(l) | isnan(c1));
    tau(idx) = (h(idx) ~= l(idx)) | (l(idx) ~= c1(idx));

    phi1 = NaN(size(c));
    idx = ~(isnan(o) | isnan(h));
    phi1(idx) = tau(idx) .* (o(idx) ~= h(idx));

    phi2 = NaN(size(c));
    idx = ~(isnan(o) | isnan(l));
    phi2(idx) = tau(idx) .* (o(idx) ~= l(idx));
    
    phi3 = NaN(size(c));
    idx = ~(isnan(c1) | isnan(h1));
    phi3(idx) = tau(idx) .* (c1(idx) ~= h1(idx));
    
    phi4 = NaN(size(c));
    idx = ~(isnan(c1) | isnan(l1));
    phi4(idx) = tau(idx) .* (c1(idx) ~= l1(idx));
  
    pt = mean(tau, "omitnan");
    po = mean(phi1, "omitnan") + mean(phi2, "omitnan");
    pc = mean(phi3, "omitnan") + mean(phi4, "omitnan");
    
    if sum(tau, "omitnan") < 2 || po == 0 || pc == 0
        s = NaN;
        return;
    end

    r1 = m-o;
    r2 = o-m1;
    r3 = m-c1;
    r4 = c1-m1;
    r5 = o-c1;
  
    d1 = r1 - tau .* mean(r1, "omitnan") / pt;
    d3 = r3 - tau .* mean(r3, "omitnan") / pt;
    d5 = r5 - tau .* mean(r5, "omitnan") / pt;
  
    x1 = -4. / po .* d1 .* r2 -4. / pc .* d3 .* r4;
    x2 = -4. / po .* d1 .* r5 -4. / pc .* d5 .* r4;
  
    e1 = mean(x1, "omitnan");
    e2 = mean(x2, "omitnan");

    v1 = mean(x1.^2, "omitnan") - e1^2;
    v2 = mean(x2.^2, "omitnan") - e2^2;
  
    vt = v1 + v2;
    if vt > 0
        s2 = (v2*e1 + v1*e2) / vt;
    else
        s2 = (e1 + e2) / 2;
    end
  
    s = sqrt(abs(s2));
    if sign && s2 < 0
        s = -s;
    end

end

