#include "edge.h"
#include <cmath>
#include <vector>
#include <stdexcept>


template <typename T>
double mean(const std::vector<T> &x){
  unsigned int n = x.size(); double sum = 0.0;
  for(unsigned int i=0; i<n; i++) sum += x[i];
  return sum / n;
}


double edge(
    const std::vector<double> &open,
    const std::vector<double> &high,
    const std::vector<double> &low,
    const std::vector<double> &close,
    const bool sign){

  unsigned int n = open.size();
  if(high.size() != n or low.size() != n or close.size() != n){
    throw std::invalid_argument(
        "open, high, low, close must have the same length"
    );
  }
  
  std::vector<double> o(n), h(n), l(n), c(n), m(n);
  for(unsigned int i=0; i<n; i++){
    o[i] = std::log(open[i]);
    h[i] = std::log(high[i]);
    l[i] = std::log(low[i]);
    c[i] = std::log(close[i]);
    m[i] = (h[i] + l[i]) / 2.;
  }
  
  std::vector<unsigned int> tau(n-1), phi1(n-1), phi2(n-1), phi3(n-1), phi4(n-1);
  std::vector<double> r1(n-1), r2(n-1), r3(n-1), r4(n-1), r5(n-1);
  for(unsigned int i=0; i<n-1; i++){
    tau[i] = (h[i+1] != l[i+1]) | (l[i+1] != c[i]);
    phi1[i] = (o[i+1] != h[i+1]) & tau[i];
    phi2[i] = (o[i+1] != l[i+1]) & tau[i];
    phi3[i] = (c[i] != h[i]) & tau[i];
    phi4[i] = (c[i] != l[i]) & tau[i];
    r1[i] = m[i+1] - o[i+1];
    r2[i] = o[i+1] - m[i];
    r3[i] = m[i+1] - c[i];
    r4[i] = c[i] - m[i];
    r5[i] = o[i+1] - c[i];
  }
  
  double pt = mean(tau);
  double m1 = mean(r1), m3 = mean(r3), m5 = mean(r5); 
  std::vector<double> d1(n-1), d3(n-1), d5(n-1);
  for(unsigned int i=0; i<n-1; i++){
    d1[i] = r1[i] - tau[i] * m1 / pt;
    d3[i] = r3[i] - tau[i] * m3 / pt;
    d5[i] = r5[i] - tau[i] * m5 / pt;
  }
  
  double po = mean(phi1) + mean(phi2), pc = mean(phi3) + mean(phi4);
  std::vector<double> x1(n-1), x2(n-1), x11(n-1), x22(n-1);
  for(unsigned int i=0; i<n-1; i++){
    x1[i] = -4./po*d1[i]*r2[i] -4./pc*d3[i]*r4[i];
    x2[i] = -4./po*d1[i]*r5[i] -4./pc*d5[i]*r4[i];
    x11[i] = x1[i] * x1[i];
    x22[i] = x2[i] * x2[i];
  }
  
  double e1 = mean(x1), e2 = mean(x2);
  double v1 = mean(x11) - e1*e1, v2 = mean(x22) - e2*e2;
  double s2 = (v2*e1 + v1*e2) / (v1 + v2);
  double s = std::sqrt(std::abs(s2));
  
  if(sign & (s2 < 0))
    s = -s;
  
  return s;
  
}
