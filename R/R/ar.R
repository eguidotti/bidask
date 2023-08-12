#' Abdi-Ranaldo Estimator
#'
#' @keywords internal
#'
AR <- function(x, width = nrow(x), method = "AR", signed = FALSE, na.rm = FALSE){

  ok <- c("AR","AR2")
  if(length(ko <- setdiff(method, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods are '%s'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))

  x <- log(x)

  M2 <- (x$HIGH+x$LOW)/2
  M1 <- lag(M2, 1)[-1,]
  C1 <- lag(x$CLOSE, 1)

  S2 <- 4*(C1-M1)*(C1-M2)

  ar <- ar2 <- NULL
  
  if("AR" %in% method) {
    ar <- rmean(S2, width = width-1, na.rm = na.rm)
    ar <- sign(ar) * sqrt(abs(ar))
    if(!signed) ar <- abs(ar)
    colnames(ar) <- "AR"
  }

  if("AR2" %in% method){
    S2[S2<0] <- 0
    S <- sqrt(S2)
    ar2 <- rmean(S, width = width-1, na.rm = na.rm)
    colnames(ar2) <- "AR2"
  }

  return(cbind(ar, ar2))

}
