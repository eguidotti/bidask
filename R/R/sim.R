#' Simulation of OHLC Prices
#'
#' This function performs simulations consisting of \code{n} periods (e.g., days) and where each period consists of a given number of \code{trades} (e.g., each minute).
#' For each trade, the true value of the stock price, \eqn{P_m}, is simulated as \eqn{P_m = P_{m-1}e^{\sigma x}}, where \eqn{\sigma} is the standard deviation per trade and \eqn{x} is a random draw from a unit normal distribution.
#' The standard deviation per period is equal to the \code{volatility} and the standard deviation per trade equals the \code{volatility} divided by the square root of the number of \code{trades}.
#' In each simulation, the trades are assumed to be observed with a given \code{probability}.
#' The bid (ask) for each trade is defined as \eqn{P_m} multiplied by one minus (plus) half the assumed bid-ask \code{spread} and we assume a 50\% chance that a bid (ask) is observed.
#' High and low prices equal the highest and lowest prices observed during the period.
#' Open and Close prices equal the first and the last price observed in the period.
#' If no trade is observed at time \eqn{t}, then the previous Close at time \eqn{t-1} is used as the Open, High, Low, and Close prices at time \eqn{t}.
#' The simulations may include close-to-open returns (e.g., overnight \code{jumps}).
#'
#' @param n the number of periods to simulate.
#' @param trades the number of trades per period.
#' @param prob the probability to observe a trade.
#' @param spread the percentage spread.
#' @param volatility the close-to-close volatility.
#' @param jump the close-to-open volatility.
#' @param drift the expected return per period.
#' @param units the units of the time period. One of: \code{sec}, \code{min}, \code{hour}, \code{day}, \code{week}, \code{month}, \code{year}.
#' @param signed if \code{TRUE}, returns signed prices indicating whether they are buys (positive prices) or sells (negative prices).
#'
#' @return Simulated OHLC prices.
#'
#' @references
#' Ardia, D., Guidotti E., & Kroencke T. A. (2021). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. 
#' Available at SSRN: \url{https://www.ssrn.com/abstract=3892335}
#'
#' Abdi, F., & Ranaldo, A. (2017). A simple estimation of bid-ask spreads from daily close, high, and low prices. The Review of Financial Studies, 30 (12), 4437-4480.
#' \doi{10.1093/rfs/hhx084}
#'
#' Corwin, S. A., & Schultz, P. (2012). A simple way to estimate bid-ask spreads from daily high and low prices. The Journal of Finance, 67 (2), 719-760.
#' \doi{10.1111/j.1540-6261.2012.01729.x}
#' 
#' @export
#'
sim <- function(
    n = 10000, 
    trades = 390, 
    prob = 1, 
    spread = 0.01, 
    volatility = 0.03, 
    jump = 0, 
    drift = 0, 
    units = "day",
    signed = FALSE){

  # sanitize units
  if(units == "minute") units <- "min"

  # check units
  valid <- c("sec","min","hour","day","week","month","year")
  if(!(units %in% valid))
    stop(sprintf("units must be one of '%s'", paste(valid, collapse = "','")))

  # total number of observations
  m <- n*trades

  # close-to-close returns
  r <- rnorm(m, mean = drift/trades, sd = volatility/sqrt(trades))

  # close-to-open returns
  idx <- 0:(n-1) * trades + 1
  r[idx] <-  r[idx] + rnorm(n, sd = jump)

  # compute prices
  z <- spread * (rbinom(m, size = 1, prob = 0.5) - 0.5)
  p <- exp(cumsum(r)) * (1 + z)
  
  # signed prices
  if(signed){
    p <- p * sign(z)
  }

  # subset observations
  keep <- as.logical(rbinom(m, size = 1, prob = prob))

  # convert to OHLC
  ohlc <- matrix(nrow = n, ncol = 4)
  prev <- p[1]
  for(i in 1:n){
    # indices of the i-th period
    idx <- (i-1)*trades + 1:trades
    # observed prices
    obs <- p[idx][keep[idx]]
    # if empty keep previous close
    if(!length(obs)) obs <- prev
    # index of last observation
    last <- length(obs)
    # unsigned prices
    uobs <- abs(obs)
    # fill matrix
    ohlc[i,] <- obs[c(1, which.max(uobs), which.min(uobs), last)]
    # store previous close
    prev <- obs[last]
  }

  # get time
  now <- Sys.time()
  if(!(units %in% c("sec","min","hour")))
    now <- as.Date(now)

  # convert to OHLC
  time <- seq(now, length = n, by = units)
  p <- xts::xts(ohlc, order.by = time)
  cn <- c("Open", "High", "Low", "Close")
  colnames(p) <- cn

  # return
  return(p)

}
