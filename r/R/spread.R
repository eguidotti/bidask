#' Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices
#'
#' This function implements several methods to estimate bid-ask spreads
#' from open, high, low, and close prices.
#'
#' @details
#' The method \code{EDGE} implements the Efficient Discrete Generalized Estimator described in Ardia, Guidotti, & Kroencke (2021).
#' 
#' The methods \code{OHL}, \code{OHLC}, \code{CHL}, \code{CHLO} implement the generalized estimators described in Ardia, Guidotti, & Kroencke (2021).
#' They can be combined by concatenating their identifiers, e.g., \code{OHLC.CHLO} uses an average of the \code{OHLC} and \code{CHLO} estimators.
#'
#' The method \code{AR} implements the estimator described in Abdi & Ranaldo (2017). \code{AR2} implements their 2-period version.
#'
#' The method \code{CS} implements the estimator described in Corwin & Schultz (2012). \code{CS2} implements their 2-period version. Both versions are adjusted for overnight (close-to-open) returns as described in the paper.
#'
#' The method \code{ROLL} implements the estimator described in Roll (1984).
#'
#' @param x \code{\link[xts]{xts}} object with columns named \code{Open}, \code{High}, \code{Low}, \code{Close}.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use. By default, the whole time series is used to compute a single spread estimate.
#' @param method the estimator(s) to use. See details.
#' @param sign whether signed estimates should be returned.
#' @param na.rm whether missing values should be ignored.
#'
#' @return Time series of spread estimates. A value of 0.01 corresponds to a spread of 1\%.
#'
#' @note 
#' Please cite \href{https://www.ssrn.com/abstract=3892335}{Ardia, Guidotti, & Kroencke (2021)} 
#' when using this package in publication.
#'
#' @references
#' Ardia, D., Guidotti E., & Kroencke T. A. (2021). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. 
#' Available at SSRN: \url{https://www.ssrn.com/abstract=3892335}
#'
#' Abdi, F., & Ranaldo, A. (2017). A simple estimation of bid-ask spreads from daily close, high, and low prices. Review of Financial Studies, 30 (12), 4437-4480.
#' \doi{10.1093/rfs/hhx084}
#' 
#' Corwin, S. A., & Schultz, P. (2012). A simple way to estimate bid-ask spreads from daily high and low prices. Journal of Finance, 67 (2), 719-760.
#' \doi{10.1111/j.1540-6261.2012.01729.x}
#' 
#' Roll, R. (1984). A simple implicit measure of the effective bid-ask spread in an efficient market. Journal of Finance, 39 (4), 1127-1139.
#' \doi{10.1111/j.1540-6261.1984.tb03897.x}
#'
#' @examples
#' # simulate open, high, low, and close prices with spread 1%
#' x <- sim(spread = 0.01)
#'
#' # estimate the spread
#' spread(x)
#' 
#' # by default this is equivalent to
#' edge(x$Open, x$High, x$Low, x$Close)
#'
#' # estimate the spread using a rolling window of 21 periods
#' spread(x, width = 21)
#'
#' # estimate the spread for each month
#' ep <- xts::endpoints(x, on = "months")
#' spread(x, width = ep)
#'
#' # use multiple estimators
#' spread(x, method = c("EDGE", "AR", "CS", "ROLL", "OHLC", "OHL.CHL"))
#'
#' @export
#'
spread <- function(x, width = nrow(x), method = "EDGE", sign = FALSE, na.rm = TRUE){

  if(!is.xts(x))
    stop("x must be a xts object")

  if(nrow(x) < 3)
    stop("x contains less than 3 observations")
  
  method <- toupper(method)
  colnames(x) <- toupper(gsub("^(.*\\b)(Open|High|Low|Close)$", "\\2", colnames(x)))

  S <- NULL
  x <- x[,intersect(colnames(x), c("OPEN", "HIGH", "LOW", "CLOSE"))]

  todo <- method
  
  m <- "EDGE"
  if(m %in% todo){
    S <- cbind(S, EDGE(x, width = width, sign = sign, na.rm = na.rm))
    todo <- setdiff(todo, m)
  }
  
  m <- c("AR","AR2")
  if(any(m %in% todo)){
    m <- intersect(todo, m)
    S <- cbind(S, AR(x, width = width, method = m, sign = sign, na.rm = na.rm))
    todo <- setdiff(todo, m)
  }

  m <- c("CS","CS2")
  if(any(m %in% todo)){
    m <- intersect(todo, m)
    S <- cbind(S, CS(x, width = width, method = m, sign = sign, na.rm = na.rm))
    todo <- setdiff(todo, m)
  }

  m <- "ROLL"
  if(m %in% todo){
    S <- cbind(S, ROLL(x, width = width, sign = sign, na.rm = na.rm))
    todo <- setdiff(todo, m)
  }
  
  if(length(todo)){
    S <- cbind(S, OHLC(x, width = width, method = todo, sign = sign, na.rm = na.rm))
  }

  return(S[,method])

}
