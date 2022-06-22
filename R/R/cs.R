#' Corwin-Schultz Estimator
#'
#' @param x \code{xts} object with columns named \code{High}, \code{Low}, \code{Close}, representing HLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param method one of \code{"CS"}, \code{"CS2"}.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds.
#' @param trim the fraction (0 to 0.5) of observations to be trimmed from each end before the spread is computed. Values of trim outside that range are taken as the nearest endpoint.
#'
#' @return Time series of spread and volatility estimates.
#'
#' @references
#' Corwin, S. A., & Schultz, P. (2012). A simple way to estimate bid-ask spreads from daily high and low prices. The Journal of Finance, 67 (2), 719-760.
#' \doi{10.1111/j.1540-6261.2012.01729.x}
#'
#' @keywords internal
#'
CS <- function(x, width = nrow(x), method = "CS", na.rm = FALSE, trim = 0){

  # check
  ok <- c("CS","CS2")
  if(length(ko <- setdiff(method, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods are '%s'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))

  # prices at time t-1
  C1 <- lag(x$CLOSE, 1)
  H1 <- lag(x$HIGH, 1)
  L1 <- lag(x$LOW, 1)

  # prices at time t
  H2 <- x$HIGH
  L2 <- x$LOW

  # adjusted prices at time t
  x$GAP <- pmax(0, C1-H2) + pmin(0, C1-L2)
  AH2 <- H2 + x$GAP
  AL2 <- L2 + x$GAP

  # compute beta
  B <- rsum(log(H2/L2)^2, width = 2, na.rm = na.rm)

  # fix approximation errors
  B[B<0] <- 0

  # compute gamma
  G <- log(pmax(AH2, H1)/pmin(AL2, L1))^2

  # compute spread
  A <- (sqrt(2*B)-sqrt(B))/(3-2*sqrt(2)) - sqrt(G/(3-2*sqrt(2)))
  S <- 2*(exp(A)-1)/(1+exp(A))

  # init
  cs <- cs2 <- NULL

  # "Monthly" adjusted
  if("CS" %in% method) {

    # compute spread
    cs <- rmean(S, width = width-1, na.rm = na.rm, trim = trim)

    # set negative spreads to zero
    cs[cs<0] <- 0

    # set name
    colnames(cs) <- "CS"

  }

  # "Two-Day" adjusted
  if("CS2" %in% method){

    # set negative spreads to zero
    S[S<0] <- 0

    # compute spread
    cs2 <- rmean(S, width = width-1, na.rm = na.rm, trim = trim)

    # set name
    colnames(cs2) <- "CS2"

  }

  # merge
  S <- cbind(cs, cs2)

  # return
  return(S)

}
