test_that("edge", {
  
  set.seed(123)
  x <- sim(prob = 0.01)
  
  s1 <- as.numeric(spread(x, method = "EDGE"))
  s2 <- edge(x$Open, x$High, x$Low, x$Close)

  expect_equal(s1, s2)
  
})

test_that("width-ep", {
  
  set.seed(123)
  x <- sim(prob = 0.01)

  width <- xts::endpoints(x, on = "months")
  s1 <- as.numeric(spread(x, width = width, method = "EDGE"))
  s2 <- sapply(2:length(width), function(i){
    m <- x[width[i-1]:width[i]]
    edge(m$Open, m$High, m$Low, m$Close)
  })
  
  expect_equal(s1, s2)
  
})

test_that("width-int", {
  
  set.seed(123)
  x <- sim(prob = 0.01)
  
  width <- 21
  s1 <- spread(x, width = width, method = "EDGE")
  s2 <- zoo::rollapplyr(x, width = width, by.column = FALSE, FUN = function(x){
    edge(x$Open, x$High, x$Low, x$Close)
  })[-(1:width-1)]
  
  expect_equal(as.numeric(s1), as.numeric(s2))
  
})

test_that("na.rm-FALSE", {
  
  set.seed(123)
  x <- sim(); x[10, 4] <- NA
  
  s <- edge(x$Open, x$High, x$Low, x$Close, na.rm = FALSE)
  
  expect_true(is.na(s))
  
})

test_that("na.rm-TRUE", {
  
  set.seed(123)
  x <- sim(); x[10, 4] <- NA
  
  s <- edge(x$Open, x$High, x$Low, x$Close, na.rm = TRUE)
  
  expect_true(!is.na(s))
  
})
