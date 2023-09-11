function s = edge(open, high, low, close, sign)
    % Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices
    %
    % Implements an efficient estimator of bid-ask spreads from open, high, low, and close prices 
    % as described in Ardia, Guidotti, & Kroencke (2021) -> https://www.ssrn.com/abstract=3892335
    %
    % Prices must be sorted in ascending order of the timestamp.
    %
    % Parameters
    % ----------
    % - `open`: vector of open prices with size Tx1
    % - `high`: vector of high prices with size Tx1
    % - `low`: vector of low prices with size Tx1
    % - `close`: vector of close prices with size Tx1
    % - `sign`: whether signed estimates should be returned
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

    tau = h ~= l | l ~= c1;
    phi1 = o ~= h & tau;
    phi2 = o ~= l & tau;
    phi3 = c1 ~= h1 & tau;
    phi4 = c1 ~= l1 & tau;
  
    pt = mean(tau, "omitnan");
    po = mean(phi1, "omitnan") + mean(phi2, "omitnan");
    pc = mean(phi3, "omitnan") + mean(phi4, "omitnan");
    
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
  
    s2 = (v2*e1 + v1*e2) / (v1 + v2);
  
    s = sqrt(abs(s2));
    if sign & s2 < 0
        s = -s;
    end

end

