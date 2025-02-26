#' Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices
#'
#' This function implements several methods to estimate bid-ask spreads
#' from open, high, low, and close prices and it is optimized for fast 
#' calculations over rolling and expanding windows.
#'
#' @details
#' The method \code{EDGE} implements the Efficient Discrete Generalized Estimator described in Ardia, Guidotti, & Kroencke (JFE, 2024).
#' 
#' The methods \code{OHL}, \code{OHLC}, \code{CHL}, \code{CHLO} implement the generalized estimators described in Ardia, Guidotti, & Kroencke (JFE, 2024).
#' They can be combined by concatenating their identifiers, e.g., \code{OHLC.CHLO} uses an average of the \code{OHLC} and \code{CHLO} estimators.
#'
#' The method \code{AR} implements the estimator described in Abdi & Ranaldo (RFS, 2017). \code{AR2} implements their 2-period version.
#'
#' The method \code{CS} implements the estimator described in Corwin & Schultz (JF, 2012). \code{CS2} implements their 2-period version. Both versions are adjusted for overnight (close-to-open) returns as described in the paper.
#'
#' The method \code{ROLL} implements the estimator described in Roll (JF, 1984).
#'
#' @param x tabular data with columns named \code{open}, \code{high}, \code{low}, \code{close} (case-insensitive).
#' @param width if an integer, the width of the rolling window. If a vector with the same length of the input prices, the width of the window corresponding to each observation. Otherwise, a vector of endpoints. By default, the full sample is used to compute a single spread estimate. See examples.
#' @param method the estimators to use. See details.
#' @param sign whether to return signed estimates.
#' @param na.rm whether to ignore missing values.
#'
#' @return A data.frame of spread estimates, or an \code{xts} object if \code{x} is of class \code{xts}. 
#' A value of 0.01 corresponds to a spread of 1\%.
#'
#' @references
#' Ardia, D., Guidotti, E., Kroencke, T.A. (2024). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. Journal of Financial Economics, 161, 103916. 
#' \doi{10.1016/j.jfineco.2024.103916}
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
#' # reduce number of threads to pass CRAN checks (you can ignore this)
#' data.table::setDTthreads(1)
#' 
#' # simulate open, high, low, and close prices with spread 1%
#' x <- sim(n = 1000, spread = 0.01)
#'
#' # estimate the spread
#' spread(x)
#' # equivalent to
#' edge(x$Open, x$High, x$Low, x$Close)
#'
#' # estimate the spread using a rolling window of 21 periods
#' s <- spread(x, width = 21)
#' tail(s)
#' # equivalent to
#' s <- edge_rolling(x$Open, x$High, x$Low, x$Close, width = 21)
#' tail(s)
#' 
#' # estimate the spread using an expanding window
#' s <- spread(x, width = 1:nrow(x))
#' tail(s)
#' # equivalent to
#' s <- edge_expanding(x$Open, x$High, x$Low, x$Close, na.rm = FALSE)
#' tail(s)
#' 
#' # estimate the spread using custom endpoints
#' ep <- c(3, 35, 100)
#' spread(x, width = ep)
#' # equivalent to
#' edge(x$Open[3:35], x$High[3:35], x$Low[3:35], x$Close[3:35])
#' edge(x$Open[35:100], x$High[35:100], x$Low[35:100], x$Close[35:100])
#'
#' # use multiple estimators
#' spread(x, method = c("EDGE", "AR", "CS", "ROLL", "OHLC", "OHL.CHL"))
#'
#' @export
#'
spread <- function(x, width = nrow(x), method = "EDGE", sign = FALSE, na.rm = FALSE){

  s <- list()
  todo <- method <- toupper(method)
  colnames(x) <- tolower(gsub("^(.*\\b)(Open|High|Low|Close)$", "\\2", colnames(x)))
  
  open <- as.numeric(x$open)
  high <- as.numeric(x$high)
  low <- as.numeric(x$low)
  close <- as.numeric(x$close)

  m <- "EDGE"
  if(m %in% todo){
    s <- c(s, EDGE(open, high, low, close, width, sign, na.rm))
    todo <- setdiff(todo, m)
  }
  
  m <- c("AR", "AR2")
  if(any(m %in% todo)){
    m <- intersect(todo, m)
    s <- c(s, AR(high, low, close, width, m, sign, na.rm))
    todo <- setdiff(todo, m)
  }

  m <- c("CS", "CS2")
  if(any(m %in% todo)){
    m <- intersect(todo, m)
    s <- c(s, CS(high, low, close, width, m, sign, na.rm))
    todo <- setdiff(todo, m)
  }

  m <- "ROLL"
  if(m %in% todo){
    s <- c(s, ROLL(close, width, sign, na.rm))
    todo <- setdiff(todo, m)
  }
  
  if(length(todo)){
    s <- c(s, OHLC(open, high, low, close, width, todo, sign, na.rm))
  }

  s <- as.data.frame(s, row.names = rownames(x))
  if(requireNamespace("xts", quietly = TRUE) & 
     requireNamespace("zoo", quietly = TRUE)
  ){
    if(xts::is.xts(x)){
      s <- xts::xts(s, order.by = zoo::index(x))
    }
  }
  
  nw <- length(width)
  if(nw == 1) s <- s[-(1:pmax(1, width - 1)), , drop = FALSE]
  else if(nw != nrow(x)) s <- s[width[-1], , drop = FALSE]
  
  return(s[, method, drop = FALSE])

}
