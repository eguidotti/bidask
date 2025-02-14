test_that("edge", {
  
  x <- read.csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc.csv")
  s <- edge(x$Open, x$High, x$Low, x$Close)
  
  expect_equal(s, 0.0101849034905478)
  
})

test_that("edge-miss", {
  
  x <- read.csv("https://raw.githubusercontent.com/eguidotti/bidask/main/pseudocode/ohlc-miss.csv")
  s <- edge(x$Open, x$High, x$Low, x$Close)
  
  expect_equal(s, 0.01013284969780197)
  
})

test_that("edge-na", {
  
  expect_true(is.na(edge(
    c(18.21, 17.61, 17.61),
    c(18.21, 17.61, 17.61),
    c(17.61, 17.61, 17.61),
    c(17.61, 17.61, 17.61)
  )))
  
})

test_that("edge-spread", {
  
  set.seed(123)
  x <- sim(prob = 0.01, units = "day")
  
  s1 <- as.numeric(spread(x, method = "EDGE"))
  s2 <- edge(x$Open, x$High, x$Low, x$Close)

  expect_equal(s1, s2)
  
})

test_that("edge-spread-monthly", {
  
  set.seed(123)
  x <- sim(prob = 0.01, units = "day")
  
  zoo::index(x) <- zoo::index(x) - as.integer(start(x))
  width <- xts::endpoints(x, on = "months")
  
  s1 <- as.numeric(spread(x, width = width, method = "EDGE"))
  s2 <- sapply(2:length(width), function(i){
    m <- x[width[i-1]:width[i]]
    edge(m$Open, m$High, m$Low, m$Close)
  })
  
  expect_equal(s1, s2)
  
})

test_that("edge-spread-rolling", {
  
  set.seed(123)
  x <- sim(prob = 0.01, units = "day")
  
  for(width in c(1, 2, 3, 4, 21, 100)){
    
    s1 <- spread(x, width = width, method = "EDGE")
    s2 <- zoo::rollapplyr(x, width = width, by.column = FALSE, FUN = function(x){
      edge(x$Open, x$High, x$Low, x$Close)
    })[-(1:max(1, width-1))]
    
    expect_equal(as.numeric(s1), as.numeric(s2), label=paste("width = ", width))
    
  }
  
})

test_that("edge-spread-sign", {
  
  set.seed(123)
  x <- sim(prob = 0.01, units = "day")
  
  width <- 21
  s1 <- spread(x, width = width, method = "EDGE", sign = TRUE)
  s2 <- zoo::rollapplyr(x, width = width, by.column = FALSE, FUN = function(x){
    edge(x$Open, x$High, x$Low, x$Close, sign = TRUE)
  })[-(1:width-1)]
  
  expect_equal(as.numeric(s1), as.numeric(s2))
  
})

test_that("edge-rolling", {
  
  set.seed(123)
  for(units in c(1, "day")) for(sign in c(TRUE, FALSE)) for(width in c(2, 3, 21)){
    
    x <- sim(prob = 0.01, units = units)
    
    s1 <- spread(x, width = width, method = "EDGE", sign = sign)
    s2 <- edge_rolling(x$Open, x$High, x$Low, x$Close, width = width, sign = sign)
    
    if(is.data.frame(x))
      idx <- as.integer(rownames(s1))
    else
      idx <- which(zoo::index(x) %in% zoo::index(s1))
    
    expect_equal(length(s2), nrow(x))
    expect_equal(as.numeric(s1[,1]), s2[idx])
    
  }
  
})

test_that("edge-rolling-na", {
  
  set.seed(123)
  x <- sim(n = 100)
  
  s1 <- edge_rolling(x$Open, x$High, x$Low, x$Close, width = nrow(x), na.rm = TRUE)
  expect_equal(sum(!is.na(s1)), 1)
  
  s2 <- edge_rolling(x$Open, x$High, x$Low, x$Close, width = c(1, nrow(x)), na.rm = TRUE)
  expect_equal(s1[!is.na(s1)], s2[!is.na(s2)])
  
})

test_that("edge-expanding", {
  
  set.seed(123)
  for(units in c(1, "day")) for(sign in c(TRUE, FALSE)) {
    
    x <- sim(prob = 0.01, units = units)
    
    s1 <- spread(x, width = 1:nrow(x), method = "EDGE", sign = sign)
    s2 <- edge_expanding(x$Open, x$High, x$Low, x$Close, sign = sign)
    
    if(is.data.frame(x))
      idx <- as.integer(rownames(s1))
    else
      idx <- which(zoo::index(x) %in% zoo::index(s1))
    
    expect_equal(length(s2), nrow(x))
    expect_equal(as.numeric(s1[,1]), s2[idx])
    
  }
  
})

test_that("spread", {
  
  set.seed(123)
  x <- sim(prob = 0.01)

  s <- spread(x[, c("Open", "High", "Low", "Close")], method = "EDGE")
  expect_equal(as.numeric(s), 0.011211623772355)
  
  s <- spread(x[, c("Open", "High", "Low", "Close")], method = "OHLC")
  expect_equal(as.numeric(s), 0.0111885179011119)
  
  s <- spread(x[, c("Open", "High", "Low", "Close")], method = "CHLO")
  expect_equal(as.numeric(s), 0.0109352942009762)
    
  s <- spread(x[, c("Open", "High", "Low")], method = "OHL", na.rm = TRUE)
  expect_equal(as.numeric(s), 0.0109503006263557)
  
  s <- spread(x[, c("High", "Low", "Close")], method = "CHL")
  expect_equal(as.numeric(s), 0.0113136390567206)
  
  s <- spread(x[, c("High", "Low", "Close")], method = "AR")
  expect_equal(as.numeric(s), 0.00874585212811397)
  
  s <- spread(x[, c("High", "Low", "Close")], method = "CS")
  expect_equal(as.numeric(s), 0.00273953769016127)
  
  s <- spread(x[, "Close", drop = FALSE], method = "ROLL")
  expect_equal(as.numeric(s), 0.0125430188215437)

})
