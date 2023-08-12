#' Corwin-Schultz Estimator
#'
#' @keywords internal
#'
CS <- function(x, width = nrow(x), method = "CS", signed = FALSE, na.rm = FALSE){

  ok <- c("CS","CS2")
  if(length(ko <- setdiff(method, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods are '%s'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))
  
  C1 <- lag(x$CLOSE, 1)
  H1 <- lag(x$HIGH, 1)
  L1 <- lag(x$LOW, 1)
  
  H2 <- x$HIGH
  L2 <- x$LOW

  x$GAP <- pmax(0, C1-H2) + pmin(0, C1-L2)
  AH2 <- H2 + x$GAP
  AL2 <- L2 + x$GAP

  B <- rsum(log(H2/L2)^2, width = 2, na.rm = na.rm)
  G <- log(pmax(AH2, H1)/pmin(AL2, L1))^2

  A <- (sqrt(2*B)-sqrt(B))/(3-2*sqrt(2)) - sqrt(G/(3-2*sqrt(2)))
  S <- 2*(exp(A)-1)/(1+exp(A))
  
  cs <- cs2 <- NULL

  if("CS" %in% method) {
    cs <- rmean(S, width = width-1, na.rm = na.rm)
    if(!signed) cs <- abs(cs)
    colnames(cs) <- "CS"
  }

  if("CS2" %in% method){
    S[S<0] <- 0
    cs2 <- rmean(S, width = width-1, na.rm = na.rm)
    colnames(cs2) <- "CS2"
  }

  return(cbind(cs, cs2))

}
