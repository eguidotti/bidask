#' Estimation of Bid-Ask Spreads from OHLC Prices
#'
#' This function estimates bid-ask spreads from open, high, low, and close prices with several methods.
#'
#' @details
#' The method \code{EDGE} implements the Efficient Discrete Generalized Estimator proposed in Ardia-Guidotti-Kroencke (2021).
#' 
#' The methods \code{O}, \code{OC}, \code{OHL}, \code{OHLC}, \code{C}, \code{CO}, \code{CHL}, \code{CHLO} implement the generalized estimators described in Ardia-Guidotti-Kroencke (2021).
#' They can be combined by concatenating their identifiers, e.g., \code{OHLC.CHLO} uses an average of the \code{OHLC} and \code{CHLO} estimators.
#' The method \code{GMM} combines the 8 OHLC estimators with the Generalized Method of Moments.
#'
#' The method \code{AR} implements the estimator proposed in Abdi & Ranaldo (2017). \code{AR2} implements the 2-period adjusted version.
#'
#' The method \code{CS} implements the estimator proposed in Corwin & Schultz (2012). \code{CS2} implements the 2-period adjusted version. Both versions are adjusted for overnight returns as described in the paper.
#'
#' The method \code{ROLL} implements the estimator proposed in Roll (1984).
#'
#' @param x \code{xts} object with columns named \code{Open}, \code{High}, \code{Low}, \code{Close}, representing OHLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use. By default, the whole time series is used to compute a single spread estimate.
#' @param method the estimator(s) to use. Choose one or more of: \code{EDGE}, \code{AR}, \code{AR2}, \code{CS}, \code{CS2}, \code{ROLL}, \code{O}, \code{OC}, \code{OHL}, \code{OHLC}, \code{C}, \code{CO}, \code{CHL}, \code{CHLO}, or \code{GMM}. See details.
#' @param probs vector of probabilities to compute the critical values when the method \code{EDGE} is selected. By default, the critical values at 2.5\% and 97.5\% are computed.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds.
#'
#' @return Time series of spread estimates.
#'
#' @references
#' Roll, R. (1984). A simple implicit measure of the effective bid-ask spread in an efficient market. The Journal of Finance, 39 (4), 1127-1139.
#' \doi{10.1111/j.1540-6261.1984.tb03897.x}
#'
#' Corwin, S. A., & Schultz, P. (2012). A simple way to estimate bid-ask spreads from daily high and low prices. The Journal of Finance, 67 (2), 719-760.
#' \doi{10.1111/j.1540-6261.2012.01729.x}
#'
#' Abdi, F., & Ranaldo, A. (2017). A simple estimation of bid-ask spreads from daily close, high, and low prices. The Review of Financial Studies, 30 (12), 4437-4480.
#' \doi{10.1093/rfs/hhx084}
#' 
#' Ardia, D., Guidotti E., & Kroencke T. A. (2021). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. 
#' Available at SSRN: \url{https://www.ssrn.com/abstract=3892335}
#'
#' @examples
#' # simulate a price process with spread 1%
#' x <- sim(spread = 0.01)
#'
#' # estimate the spread with EDGE
#' edge(x$Open, x$High, x$Low, x$Close)
#' 
#' # by default this is equivalent to
#' spread(x)
#'
#' # use a rolling window of 21 periods
#' spread(x, width = 21)
#'
#' # compute the spread for each month
#' ep <- xts::endpoints(x, on = "months")
#' spread(x, width = ep)
#'
#' # compute the critical values at 5% and 95%
#' spread(x, probs = c(0.05, 0.95))
#'
#' # use multiple estimators
#' spread(x, method = c("EDGE", "AR", "CS", "ROLL", "OHLC", "OHL.CHL", "GMM"))
#'
#' @export
#'
spread <- function(x, width = nrow(x), method = "EDGE", probs = c(0.025, 0.975), na.rm = FALSE){

  if(!is.xts(x))
    stop("x must be a xts object")

  method <- toupper(method)
  colnames(x) <- toupper(gsub("^(.*\\b)(Open|High|Low|Close)$", "\\2", colnames(x)))

  S <- NULL
  x <- x[,intersect(colnames(x), c("OPEN", "HIGH", "LOW", "CLOSE"))]

  m <- "EDGE"
  if(m %in% method){
    S <- cbind(S, EDGE(x, width = width, probs = probs, na.rm = na.rm))
    method <- setdiff(method, m)
  }
  
  m <- "GMM"
  if(m %in% method){
    S <- cbind(S, GMM(x, width = width, na.rm = na.rm))
    method <- setdiff(method, m)
  }

  m <- c("AR","AR2")
  if(any(m %in% method)){
    m <- intersect(method, m)
    S <- cbind(S, AR(x, width = width, method = m, na.rm = na.rm))
    method <- setdiff(method, m)
  }

  m <- c("CS","CS2")
  if(any(m %in% method)){
    m <- intersect(method, m)
    S <- cbind(S, CS(x, width = width, method = m, na.rm = na.rm))
    method <- setdiff(method, m)
  }

  m <- "ROLL"
  if(m %in% method){
    S <- cbind(S, ROLL(x, width = width, na.rm = na.rm))
    method <- setdiff(method, m)
  }
  
  if(length(method)){
    S <- cbind(S, OHLC(x, width = width, method = method, na.rm = na.rm))
  }

  return(S)

}
