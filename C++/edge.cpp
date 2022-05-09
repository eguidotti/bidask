#include "edge.h"
#include <cmath>
#include <vector>
#include <stdexcept>


double edge(
    const std::vector<double> &open,
    const std::vector<double> &high,
    const std::vector<double> &low,
    const std::vector<double> &close){
  
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
  
  int x1_n=0, x2_n=0, n1_n=0, n2_n=0, n3_n=0, n4_n=0, n5_n=0;
  double x1_s=0, x2_s=0, n1_s=0, n2_s=0, n3_s=0, n4_s=0, n5_s=0;
  double x1_ss=0, x2_ss=0;
  
  double tmp;
  for(unsigned int i=1; i<n; i++){
    if(std::isfinite(m[i]) and std::isfinite(o[i]) and 
         std::isfinite(m[i-1]) and std::isfinite(c[i-1])){
      
      tmp = (m[i] - o[i]) * (o[i] - m[i-1]) + (m[i] - c[i-1]) * (c[i-1] - m[i-1]);
      x1_s += tmp;
      x1_ss += tmp * tmp;
      x1_n++;  
      
      tmp = (m[i] - o[i]) * (o[i] - c[i-1]) + (o[i] - c[i-1]) * (c[i-1] - m[i-1]);
      x2_s += tmp;
      x2_ss += tmp * tmp;
      x2_n++;  
      
      n1_s += int(o[i] == h[i]);
      n1_n++;  
      
      n2_s += int(o[i] == l[i]);
      n2_n++;  
      
      n3_s += int(c[i-1] == h[i-1]);
      n3_n++;  
      
      n4_s += int(c[i-1] == l[i-1]);
      n4_n++;  
      
      n5_s += int(h[i] == l[i] and l[i] == c[i-1]);
      n5_n++;  
      
    }
  }
  
  double 
    e1 = x1_s / x1_n,
    e2 = x2_s / x2_n,
    
    v1 = x1_n / (x1_n-1.) * (x1_ss / x1_n - std::pow(x1_s / x1_n, 2)),
    v2 = x2_n / (x2_n-1.) * (x2_ss / x2_n - std::pow(x2_s / x2_n, 2)),
    
    w1 = v2 / (v1 + v2),
    w2 = v1 / (v1 + v2),
    k = 4 * w1 * w2,
    
    n1 = n1_s / n1_n,
    n2 = n2_s / n2_n,
    n3 = n3_s / n3_n,
    n4 = n4_s / n4_n,
    n5 = n5_s / n5_n,
    
    s2 = -4 * (w1 * e1 + w2 * e2) / ((1 - k * (n1 + n2) / 2) + (1 - n5) * (1 - k * (n3 + n4) / 2));
  
  double s=0;
  if(s2 > 0){
    s = std::sqrt(s2);
  }
  
  return(s);
}
