## ---- echo = FALSE, eval=TRUE--------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#"
)
library(pulsar)
pulsarchunks = TRUE
getconfig    = TRUE

## ---- eval=FALSE---------------------------------------------------------
#  library(devtools)
#  install_github("zdk123/pulsar")
#  library(pulsar)

## ---- eval=pulsarchunks, message=FALSE-----------------------------------
library(huge)
set.seed(10010)
p <- 40 ; n <- 2000
dat  <- huge.generator(n, p, "hub", verbose=FALSE, v=.1, u=.35)
lmax <- getMaxCov(dat$sigmahat)
lams <- getLamPath(lmax, lmax*.05, len=40)

## ---- eval=pulsarchunks, message=FALSE-----------------------------------
hugeargs <- list(lambda=lams, verbose=FALSE)
time1    <- system.time(
out.p    <- pulsar(dat$data, fun=huge, fargs=hugeargs, rep.num=20,
                   criterion='stars', seed=10010)
            )
fit.p    <- refit(out.p)

## ---- eval=TRUE, message=FALSE-------------------------------------------
out.p
fit.p

## ---- eval=pulsarchunks--------------------------------------------------
time2 <- system.time(
out.b <- pulsar(dat$data, fun=huge, fargs=hugeargs, rep.num=20, criterion='stars',
                lb.stars=TRUE, ub.stars=TRUE, seed=10010)
               )

## ---- eval=TRUE----------------------------------------------------------
time2[[3]] < time1[[3]]
opt.index(out.p, 'stars') == opt.index(out.b, 'stars')

## ---- eval=pulsarchunks--------------------------------------------------
library(QUIC)
quicr <- function(data, lambda) {
    S    <- cov(data)
    est  <- QUIC::QUIC(S, rho=1, path=lambda, msg=0, tol=1e-2)
    path <-  lapply(seq(length(lambda)), function(i) {
                tmp <- est$X[,,i]; diag(tmp) <- 0
                as(tmp!=0, "lgCMatrix")
    })
    est$path <- path
    est
}

## ---- eval=pulsarchunks--------------------------------------------------
quicargs <- list(lambda=lams)
nc <- if (.Platform$OS.type == 'unix') 2 else 1
out.q <- pulsar(dat$data, fun=quicr, fargs=quicargs, rep.num=100, criterion='stars',
                lb.stars=TRUE, ub.stars=TRUE, ncores=nc, seed=10010)

## ---- eval=pulsarchunks--------------------------------------------------
out.q2 <- update(out.q, criterion=c('stars', 'gcd'))
opt.index(out.q2, 'gcd') <- get.opt.index(out.q2, 'gcd')
fit.q2 <- refit(out.q2)

## ---- eval=TRUE, fig.width=12, fig.height=6, message=FALSE---------------
plot(out.q2, scale=TRUE)

## ---- eval=TRUE, fig.width=18, fig.height=6, message=FALSE---------------
starserr <- sum(fit.q2$refit$stars != dat$theta)/p^2
gcderr   <- sum(fit.q2$refit$gcd   != dat$theta)/p^2
gcderr < starserr

## install.packages('network')
library(network)
truenet  <- network(dat$theta)
starsnet <- network(summary(fit.q2$refit$stars))
gcdnet   <- network(summary(fit.q2$refit$gcd))
par(mfrow=c(1,3))
coords <- plot(truenet, usearrows=FALSE, main="TRUE")
plot(starsnet, coord=coords, usearrows=FALSE, main="StARS")
plot(gcdnet, coord=coords, usearrows=FALSE, main="StARS+GCD")

## ---- eval=getconfig-----------------------------------------------------
url <- "https://raw.githubusercontent.com/zdk123/pulsar/master/inst/extdata"
url <- paste(url, "BatchJobsSerialTest.R", sep="/") # Serial mode
download.file(url, destfile=".BatchJobs.R")

## ---- eval=pulsarchunks, message=FALSE-----------------------------------
## uncomment below if BatchJobs is not already installed
# install.packages('BatchJobs')
library(BatchJobs)
out.batch <- batch.pulsar(dat$data, fun=quicr, fargs=quicargs, rep.num=100,
                          criterion='stars', seed=10010
                          #, cleanup=TRUE
                         )

## ---- eval=TRUE, message=FALSE-------------------------------------------
opt.index(out.q, 'stars') == opt.index(out.batch, 'stars')

## ---- eval=pulsarchunks, message=FALSE-----------------------------------
out.bbatch <- update(out.batch, criterion=c('stars', 'gcd'),
                     lb.stars=TRUE, ub.stars=TRUE)

## ---- eval=TRUE, message=FALSE-------------------------------------------
opt.index(out.bbatch, 'stars') == opt.index(out.batch, 'stars')

