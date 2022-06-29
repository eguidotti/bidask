#' Abdi-Ranaldo Estimator
#'
#' @param x \code{xts} object with columns named \code{High}, \code{Low}, \code{Close}, representing HLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param method one of \code{"AR"}, \code{"AR2"}.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds.
#'
#' @return Time series of spread estimates.
#'
#' @references
#' Abdi, F., & Ranaldo, A. (2017). A simple estimation of bid-ask spreads from daily close, high, and low prices. The Review of Financial Studies, 30 (12), 4437-4480.
#' \doi{10.1093/rfs/hhx084}
#'
#' @keywords internal
#'
AR <- function(x, width = nrow(x), method = "AR", na.rm = FALSE){

  # check
  ok <- c("AR","AR2")
  if(length(ko <- setdiff(method, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods are '%s'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))

  # log prices
  x <- log(x)

  # compute mid prices
  M2 <- (x$HIGH+x$LOW)/2
  M1 <- lag(M2, 1)[-1,]
  C1 <- lag(x$CLOSE, 1)

  # compute square spreads
  S2 <- 4*(C1-M1)*(C1-M2)

  # init
  ar <- ar2 <- NULL

  # "Monthly" adjusted
  if("AR" %in% method) {

    # compute average squared spread
    ar <- rmean(S2, width = width-1, na.rm = na.rm)

    # set negative estimates to zero
    ar[ar<0] <- 0

    # square root
    ar <- sqrt(ar)

    # set names
    colnames(ar) <- "AR"

  }

  # "Two-Day" adjusted
  if("AR2" %in% method){

    # set negative squared spreads to zero
    S2[S2<0] <- 0

    # square root
    S <- sqrt(S2)

    # compute average spread
    ar2 <- rmean(S, width = width-1, na.rm = na.rm)

    # set names
    colnames(ar2) <- "AR2"

  }

  # merge
  S <- cbind(ar, ar2)

  # return
  return(S)

}
