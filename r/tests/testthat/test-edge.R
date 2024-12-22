test_that("edge", {
  
  set.seed(123)
  x <- sim(prob = 0.01)
  
  s1 <- as.numeric(spread(x, method = "EDGE"))
  s2 <- edge(x$Open, x$High, x$Low, x$Close)

  expect_equal(s1, s2)
  
})

test_that("edge-monthly", {
  
  set.seed(123)
  x <- sim(prob = 0.01)
  
  zoo::index(x) <- zoo::index(x) - as.integer(start(x))
  width <- xts::endpoints(x, on = "months")
  
  s1 <- as.numeric(spread(x, width = width, method = "EDGE"))
  s2 <- sapply(2:length(width), function(i){
    m <- x[width[i-1]:width[i]]
    edge(m$Open, m$High, m$Low, m$Close)
  })
  
  expect_equal(s1, s2)
  
})

test_that("edge-rolling", {
  
  set.seed(123)
  x <- sim(prob = 0.01)
  
  for(width in c(1, 2, 3, 4, 21, 100)){
    
    s1 <- spread(x, width = width, method = "EDGE")
    s2 <- zoo::rollapplyr(x, width = width, by.column = FALSE, FUN = function(x){
      edge(x$Open, x$High, x$Low, x$Close)
    })[-(1:max(1, width-1))]
    
    expect_equal(as.numeric(s1), as.numeric(s2), label=paste("width = ", width))
    
  }
  
})

test_that("edge-sign", {
  
  set.seed(123)
  x <- sim(prob = 0.01)
  
  width <- 21
  s1 <- spread(x, width = width, method = "EDGE", sign = TRUE)
  s2 <- zoo::rollapplyr(x, width = width, by.column = FALSE, FUN = function(x){
    edge(x$Open, x$High, x$Low, x$Close, sign = TRUE)
  })[-(1:width-1)]
  
  expect_equal(as.numeric(s1), as.numeric(s2))
  
})

test_that("edge-nan", {
  
  expect_true(is.nan(edge(
    c(18.21, 17.61, 17.61),
    c(18.21, 17.61, 17.61),
    c(17.61, 17.61, 17.61),
    c(17.61, 17.61, 17.61)
  )))
  
})
