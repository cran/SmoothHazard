# 0 : health state
# 1 : illness state
# 2 : death state
#' Predictions for an illness-death model using either a penalized likelihood
#' approach or a Weibull parametrization.
#' 
#' Predict transition probabilities and cumulative probabilities from an object
#' of class \code{idmSplines} with confidence intervals are calculated.
#' 
#' @param object an \code{idm} class objects returned by a call to the
#'     \link{idm} function
#' @param s time point at which prediction is made.
#' @param t time horizon for prediction.
#' @param newdata A data frame with covariate values for prediction.
#' @param nsim number of simulations for the confidence intervals
#'     calculations.  The default is 200.
#' @param seed Seed passed to \code{set.seed} for Monte Carlo
#'     simulation of confidence intervals.
#' @param conf.int Level of confidence, i.e., a value between 0 and 1,
#'     the default is \code{0.95}.  The default is also used when
#'     \code{conf.int=TRUE}.  To avoid computation of confidence
#'     intervals, set \code{conf.int} to FALSE or NULL.
#' @param lifeExpect Logical. If \code{TRUE} compute life
#'     expectancies, i.e., \code{t=Inf}.
#' @param maxtime The upper limit of integration for calculations of life expectancies from Weibull parametrizations.
#' @param ... other parameters.
#' @return a list containing the following predictions with pointwise
#'     confidence intervals: \item{p00}{the transition probability
#'     \eqn{p_{00}}.}  \item{p01}{the transition probability
#'     \eqn{p_{01}}.} \item{p11}{the transition probability
#'     \eqn{p_{11}}.} \item{p12}{the transition probability
#'     \eqn{p_{12}}.} \item{p02_0}{the probability of direct
#'     transition from state 0 to state 2.} \item{p02_1}{the
#'     probability of transition from state 0 to state 2 via state 1.}
#'     \item{p02}{transition probability \eqn{p_{02}}. Note that
#'     \code{p02}=\code{p_02_0}+\code{p02_1}.} \item{F01}{the lifetime
#'     risk of disease. \code{F01}=\code{p01}+\code{p02_1}.}
#'     \item{F0.}{the probability of exit from state
#'     0. \code{F0.}=\code{p02_0}+\code{p01}+\code{p02_1}.}
#' @author R: Celia Touraine <Celia.Touraine@@isped.u-bordeaux2.fr>
#'     and Thomas Alexander Gerds <tag@@biostat.ku.dk> Fortran: Pierre
#'     Joly <Pierre.Joly@@isped.u-bordeaux2.fr>
#' @seealso \link{idm}
#' @keywords methods
#' @examples
#'
#' \donttest{
#' set.seed(100)
#' d=simulateIDM(n = 200)
#' fit <- idm(formula01=Hist(time=list(L,R),event=seen.ill)~X1+X2+X3,
#'                formula02=Hist(time=observed.lifetime,event=seen.exit)~X1+X2+X3,
#'                data=d,conf.int=FALSE)
#' predict(fit,s=0,t=80,conf.int=FALSE,lifeExpect=FALSE)
#' predict(fit,s=0,t=80,nsim=4,conf.int=TRUE,lifeExpect=FALSE)
#' predict(fit,s=0,t=80,nsim=4,conf.int=FALSE,lifeExpect=TRUE)
#' 
#' data(Paq1000)
#' library(prodlim)
#' fit.paq <- idm(formula02=Hist(time=t,event=death,entry=e)~certif,
#' formula01=Hist(time=list(l,r),event=dementia)~certif,data=Paq1000)
#' 
#' predict(fit.paq,s=70,t=80,newdata=data.frame(certif=1))
#' predict(fit.paq,s=70,lifeExpect=TRUE,newdata=data.frame(certif=1))
#' 
#' fit.splines <-  idm(formula02=Hist(time=t,event=death,entry=e)~certif,
#' 		formula01=Hist(time=list(l,r),event=dementia)~certif,
#'                 formula12=~1,
#'                 method="Splines",
#' 		data=Paq1000)
#' 
#' predict(fit.splines,s=70,t=80,newdata=data.frame(certif=1))
#' predict(fit.splines,s=70,t=80,lifeExpect=TRUE,newdata=data.frame(certif=1),nsim=20)
#' 
#' 
#' }
#'
#' @export
predict.idm <- function(object,s,t,newdata,nsim=200,seed=21,conf.int=.95,lifeExpect=FALSE,maxtime,...) {
    ## if (lifeExpect==TRUE) t <- Inf
    if (lifeExpect==TRUE) {
        t <- Inf
        if (!missing(maxtime) && is.numeric(maxtime)) {
            maxtime <- min(maxtime,object$maxtime)
        } else {
            maxtime <- object$maxtime
        }
    }
    if (any(s>t)) {stop("You must respect the condition 's<t' to calculate p(s,t)")}
    do.conf.int <- !is.null(conf.int) && !is.na(conf.int) && !conf.int==FALSE
    if (is.logical(conf.int)) conf.int <- .95
    if (do.conf.int == TRUE){
        stopifnot(0<conf.int && conf.int<1)
        if (nsim < 2) stop("Need at least two simulations to construct confidence limits.")
    }
    if (missing(t) && lifeExpect==FALSE) stop("Argument t is missing.")
    if (lifeExpect==TRUE) t <- Inf
    if (missing(s)) stop("Argument s is missing.")
    ## if (missing(t) || is.infinite(t)) lifeExpect <- TRUE
    # if covariates: cov=c(cov1,cov2,cov3,...)
    nvar01 <- object$NC[1]
    nvar02 <- object$NC[2]
    nvar12 <- object$NC[3]
    if (!missing(newdata)){
        # if (NROW(newdata)>1) stop("Argument newdata has more than one row\n.Currently this function works only for one covariate constallation at a time.")
        if (length(object$Xnames01)>0)
            Z01 <- as.matrix(model.frame(formula=update.formula(formula(object$terms$Formula01),NULL~.),
                                         data=newdata))
        else 
            Z01 <- 0
        if (length(object$Xnames02)>0)
            Z02 <- as.matrix(model.frame(formula=update.formula(formula(object$terms$Formula02),NULL~.),data=newdata))
        else
            Z02 <- 0
        if (length(object$Xnames12)>0)
            Z12 <- as.matrix(model.frame(formula=update.formula(formula(object$terms$Formula12),NULL~.),data=newdata))
        else
            Z12 <- 0
    }else{
        vars <- unique(c(object$Xnames01,object$Xnames02,object$Xnames12))
        newdata <- data.frame(matrix(0,ncol=pmax(1,length(vars))))
        names(newdata) <- vars
        Z01 <- matrix(rep(0,length(object$Xnames01)),nrow=1)
        Z02 <- matrix(rep(0,length(object$Xnames02)),nrow=1)
        Z12 <- matrix(rep(0,length(object$Xnames12)),nrow=1)
    }
    if(nvar01 > 0){
        beta01 <- object$coef[1:nvar01]
        names(beta01) <- paste0("beta01.",names(beta01))
        bZ01 <- sum(Z01 * beta01)
    }else{
        bZ01 <- 0
        beta01 <- NULL
    }
    if (nvar02 != 0) {
        beta02 <- object$coef[(nvar01+1):(nvar01+nvar02)]
        names(beta02) <- paste0("beta02.",names(beta02))
        bZ02 <- sum(Z02 * beta02)
    }else{
        beta02 <- NULL
        bZ02 <- 0
    }
    if (nvar12 != 0) {
        beta12 <- object$coef[(nvar01+nvar02+1):(nvar01+nvar02+nvar12)]
        names(beta12) <- paste0("beta12.",names(beta12))
        bZ12 <- sum(Z12 * beta12)
    }else{
        beta12 <- NULL
        bZ12 <- 0
    }
    ## Splines
    if (object$method=="Splines"){
        nknots01 <- object$nknots01
        nknots02 <- object$nknots02
        nknots12 <- object$nknots12
        knots01 <- object$knots01
        knots02 <- object$knots02
        knots12 <- object$knots12
        the01 <- object$theta01
        names(the01) <- paste0("the01.",1:length(the01))
        the02 <- object$theta02
        names(the02) <- paste0("the02.",1:length(the02))
        the12 <- object$theta12
        names(the12) <- paste0("the12.",1:length(the12))
        if (do.conf.int == TRUE){
            ### conf.int prediction by Monte-Carlo
            Vmean <- c(the01,the02,the12,beta01,beta02,beta12) # vector of estimates
            set.seed(seed)
            X <- mvtnorm::rmvnorm(nsim,Vmean,object$V)
            colnames(X) <- names(Vmean)
            # 1 set of simulated parameters for each element of the list
            Xtheta01=X[,names(the01)]^2
            Xtheta02=X[,names(the02)]^2
            Xtheta12=X[,names(the12)]^2
            if (!is.null(beta01))
                linPred01=X[,names(beta01),drop=FALSE] %*% t(Z01)
            else
                linPred01=matrix(0,nrow=nsim,ncol=1)
            if (!is.null(beta02))
                linPred02=X[,names(beta02),drop=FALSE] %*% t(Z02)
            else
                linPred02=matrix(0,nrow=nsim,ncol=1)
            if (!is.null(beta12))
                linPred12=X[,names(beta12),drop=FALSE] %*% t(Z12)
            else
                linPred12=matrix(0,nrow=nsim,ncol=1)
            if (lifeExpect==TRUE){
                simResults <- do.call("rbind",
                                      lapply(1:nsim,function(i){
                                          lifexpect0.idmPl(s,
                                                           knots01,
                                                           nknots01,
                                                           Xtheta01[i,],
                                                           knots12,
                                                           nknots12,
                                                           Xtheta12[i,],
                                                           knots02,
                                                           nknots02,
                                                           Xtheta02[i,],
                                                           linPred01[i,],
                                                           linPred12[i,],
                                                           linPred02[i,])
                                      }))
            }else{
                simResults <- do.call("rbind",
                                      lapply(1:nsim,function(i){
                                          Predict0.idmPl(s,
                                                         t,
                                                         knots01,
                                                         nknots01,
                                                         Xtheta01[i,],
                                                         knots12,
                                                         nknots12,
                                                         Xtheta12[i,],
                                                         knots02,
                                                         nknots02,
                                                         Xtheta02[i,],
                                                         linPred01[i,],
                                                         linPred12[i,],
                                                         linPred02[i,])
                                      }))
            }
            q.lower <- (1-conf.int)/2
            q.upper <- 1-q.lower
            ci <- apply(simResults,2,function(x)quantile(unlist(x),c(q.lower,q.upper)))
        }
        if (lifeExpect==TRUE){
            transprob <- unlist(lifexpect0.idmPl(s,
                                                 knots01,
                                                 nknots01,
                                                 the01^2,
                                                 knots12,
                                                 nknots12,
                                                 the12^2,
                                                 knots02,
                                                 nknots02,
                                                 the02^2,
                                                 bZ01,
                                                 bZ12,
                                                 bZ02))
        }else{
            transprob <- unlist(Predict0.idmPl(s,t,knots01,nknots01,the01^2,knots12,nknots12,the12^2,knots02,nknots02,the02^2,bZ01,bZ12,bZ02))
        }
    }else {
        a01 <- object$modelPar[1]
        b01 <- object$modelPar[2]
        a02 <- object$modelPar[3]
        b02 <- object$modelPar[4]
        a12 <- object$modelPar[5]
        b12 <- object$modelPar[6]
        if (do.conf.int==TRUE) {
            ## conf.int prediction by Monte-Carlo
            ## vector of parameter estimates
            Vmean <- c(sqrt(a01),sqrt(b01),sqrt(a02),sqrt(b02),sqrt(a12),sqrt(b12),beta01,beta02,beta12)
            names(Vmean) <- c("a01","b01","a02","b02","a12","b12",names(beta01),names(beta02),names(beta12))
            set.seed(seed)
            X <- mvtnorm::rmvnorm(nsim,Vmean,object$V)
            colnames(X) <- names(Vmean)
            # set of simulated parameters for each element of the list
            Xa01=X[,"a01"]^2
            Xb01=1/(X[,"b01"]^2)
            Xa02=X[,"a02"]^2
            Xb02=1/(X[,"b02"]^2)
            Xa12=X[,"a12"]^2
            Xb12=1/(X[,"b12"]^2)
            if (!is.null(beta01))
                linPred01=X[,names(beta01),drop=FALSE] %*% t(Z01)
            else
                linPred01=matrix(0,nrow=nsim,ncol=1)
            if (!is.null(beta02))
                linPred02=X[,names(beta02),drop=FALSE] %*% t(Z02)
            else
                linPred02=matrix(0,nrow=nsim,ncol=1)
            if (!is.null(beta12))
                linPred12=X[,names(beta12),drop=FALSE] %*% t(Z12)
            else
                linPred12=matrix(0,nrow=nsim,ncol=1)
            if (lifeExpect==TRUE){
                simResults <- do.call("rbind",
                                      lapply(1:nsim,function(i){
                                          lifexpect0.idmWeib(s,
                                                             a01=Xa01[[i]],
                                                             b01=Xb01[[i]],
                                                             a02=Xa02[[i]],
                                                             b02=Xb02[[i]],
                                                             a12=Xa12[[i]],
                                                             b12=Xb12[[i]],
                                                             bZ01=linPred01[[i]],
                                                             bZ02=linPred02[[i]],
                                                             bZ12=linPred12[[i]],max=maxtime)
                                      }))
            }else{
                simResults <- do.call("rbind",
                                      lapply(1:nsim,function(i){
                                          Predict0.idmWeib(s,
                                                           t,
                                                           a01=Xa01[[i]],
                                                           b01=Xb01[[i]],
                                                           a02=Xa02[[i]],
                                                           b02=Xb02[[i]],
                                                           a12=Xa12[[i]],
                                                           b12=Xb12[[i]],
                                                           bZ01=linPred01[[i]],
                                                           bZ02=linPred02[[i]],
                                                           bZ12=linPred12[[i]])
                                      }))
            }
            q.lower <- (1-conf.int)/2
            q.upper <- 1-q.lower
            ci <- apply(simResults,2,function(x)quantile(unlist(x),c(q.lower,q.upper)))
        }
        if (lifeExpect==TRUE){
            transprob <- unlist(lifexpect0.idmWeib(s,
                                                   a01,
                                                   1/b01,
                                                   a02,
                                                   1/b02,
                                                   a12,
                                                   1/b12,
                                                   bZ01,
                                                   bZ02,
                                                   bZ12,max=maxtime))
        }else{
            transprob <- unlist(Predict0.idmWeib(s,
                                                 t,
                                                 a01,
                                                 1/b01,
                                                 a02,
                                                 1/b02,
                                                 a12,
                                                 1/b12,
                                                 bZ01,
                                                 bZ02,
                                                 bZ12))
        }
    }
    if (do.conf.int==TRUE){
        transprob <- data.frame(cbind(transprob,t(ci)))
        names(transprob) <- c("Estimate",paste("Lower",round(100*conf.int),sep="."),paste("Upper",round(100*conf.int),sep="."))
        transprob <- cbind("Parameter"=rownames(transprob),transprob)
        rownames(transprob) <- NULL
    }else{
        transprob <- data.frame(cbind(transprob))
        names(transprob) <- c("Estimate")
        transprob <- cbind("Parameter"=rownames(transprob),transprob)
        rownames(transprob) <- NULL
    }
    out <- list(transprob=transprob)
    out <- c(out,list(newdata=newdata))
    out <- c(out,list(s=s,t=t,conf.int=ifelse(do.conf.int,conf.int,FALSE)))
    class(out) <- "predict.idm"
    out
}

Predict0.idmPl <- function(s,t,knots01,nknots01,the01,knots12,nknots12,the12,knots02,nknots02,the02,bZ01=0,bZ12=0,bZ02=0) {
    if (s>(min(knots01[nknots01+6],knots02[nknots02+6],knots12[nknots12+6]))) {stop("argument s is off")}    
    if (any(t>knots12[nknots12+6])) {stop("argument t is off")}
    if (any(s<knots01[1])) {stop("argument s is off")}
    p11 <- S.pl(s,t,knots12,nknots12,the12,bZ12)
    p12 <- 1-p11
    p00 <- S.pl(s,t,knots01,nknots01,the01,bZ01)*S.pl(s,t,knots02,nknots02,the02,bZ02)
    p02_0 <- sapply(t,function(t) {integrate(f=function(x){S.pl(s,x,knots01,nknots01,the01,bZ01)*S.pl(s,x,knots02,nknots02,the02,bZ02)*intensity(times=x,knots=knots02,number.knots=nknots02,theta=the02,linear.predictor=bZ02)$intensity},lower=s,upper=t)$value})
    p01 <- sapply(t,function(t) {integrate(f=function(x){S.pl(s,x,knots01,nknots01,the01,bZ01)*S.pl(s,x,knots02,nknots02,the02,bZ02)*intensity(times=x,knots=knots01,number.knots=nknots01,theta=the01,linear.predictor=bZ01)$intensity*S.pl(x,t,knots12,nknots12,the12,bZ12)},lower=s,upper=t)$value})
    p02_1 <- 1-p00-p02_0-p01
    p02 <- p02_0+p02_1
    RM<- integrate(f = function(x) {S.pl(s, x, knots01, nknots01, the01, bZ01) * S.pl(s, x, knots02, nknots02, the02, bZ02) }, lower = s, upper = t)$value
    F01<- integrate(f = function(x) {S.pl(s, x, knots01, nknots01, the01, bZ01) * S.pl(s, x, knots02, nknots02, the02, bZ02) * intensity(times = x, knots = knots01, number.knots = nknots01, theta = the01,linear.predictor = bZ01)$intensity }, lower = s, upper = t)$value
    list(p00=p00,p01=p01,p11=p11,p12=p12,p02_0=p02_0,p02_1=p02_1,p02=p02,F01=F01,F0.=p02_0+p01+p02_1, RM=RM)
}

Predict0.idmWeib <- function(s,t,a01,b01,a02,b02,a12,b12,bZ01=0,bZ02=0,bZ12=0) {
    p11 = S.weib(s,t,a12,b12,bZ12)
    p12 = 1-p11
    p00 = S.weib(s,t,a01,b01,bZ01)*S.weib(s,t,a02,b02,bZ02)
    p02_0 = sapply(t,function(t) {integrate(f=function(x){S.weib(s,x,a01,b01,bZ01)*S.weib(s,x,a02,b02,bZ02)*iweibull(x,a02,b02,bZ02)},lower=s,upper=t)$value })
    p01 = sapply(t,function(t) {integrate(f=function(x){S.weib(s,x,a01,b01,bZ01)*S.weib(s,x,a02,b02,bZ02)*iweibull(x,a01,b01,bZ01)*S.weib(x,t,a12,b12,bZ12)},lower=s,upper=t)$value})
    p02_1 = 1-p00-p02_0-p01
    p02 = p02_0+p02_1
    RM= integrate(f = function(x) {S.weib(s, x, a01, b01, bZ01) * S.weib(s, x, a02, b02, bZ02)}, lower = s, upper = t)$value
    F01= integrate(f = function(x) {S.weib(s, x, a01, b01, bZ01) * S.weib(s, x, a02, b02, bZ02)*iweibull(x,a01,b01,bZ01)}, lower = s, upper = t)$value
    ## return(list(p00=p00,p01=p01,p11=p11,p12=p12,p02_0=p02_0,p02_1=p02_1,p02=p02,F01=p01+p02_1,F0.=p02_0+p01+p02_1))
    list(p00=p00,p01=p01,p11=p11,p12=p12,p02_0=p02_0,p02_1=p02_1,p02=p02,F01=F01,F0.=p02_0+p01+p02_1, RM=RM)
}

# a = shape parameter
# b = scale parameter
iweibull <- function(x,a,b,bZ=0) {
    res = (a/b) * (x/b)**(a-1) * exp(bZ)
    return(res) 
}

# S(s,t) = S(t)/S(s)
# if S(s)=0, S(s,t)=0
S.weib <- function(s,t,a,b,bZ=0) {	
    res <- 0
    St <- (1-pweibull(t,shape=a,scale=b))^(exp(bZ))
    Ss <- (1-pweibull(s,shape=a,scale=b))^(exp(bZ))
    if (length(s)==1){
        if (Ss==0){res <- 0}
        else{res <- St/Ss}
    }else{
         idx0 <- which(Ss==0)
         idx <- which(Ss!=0)
         res[idx0] <- 0 
         res[idx] <- St/Ss[idx]
     }
    return(res)
}



A <- function(s,t,zi,nknots,the,bZ=0) {
    res=rep(0,length(t))
    TF = (t>=zi[length(zi)])
    ind = which(TF)
    if (sum(TF)!=0) {res[ind]=intensity((zi[nknots+6]-10^-5),zi,nknots,the,bZ)$cumul.intensity-intensity(s,zi,nknots,the,bZ)$cumul.intensity}
    TF = (t<zi[length(zi)])
    ind = which(TF)
    if (sum(TF)!=0) {res[ind]=intensity(t[ind],zi,nknots,the,bZ)$cumul.intensity-intensity(s,zi,nknots,the,bZ)$cumul.intensity}
    return(res)
}

### Survival function with two time s, t
# S(s,t) = S(t)/S(s)
#        = exp(-A(s,t))
S.pl <- function(s,t,zi,nknots,the,bZ=0) {
    if (length(t)>=length(s)){
        res=rep(0,length(t))
        TF = (t>zi[length(zi)])
        ind = which(TF)
        if (sum(TF)!=0) {res[ind]=0}
        TF = (t<=zi[length(zi)])
        ind = which(TF)
        if (sum(TF)!=0) {res[ind]=intensity(t[ind],zi,nknots,the,bZ)$survival/intensity(s,zi,nknots,the,bZ)$survival}
    }else{		
         res=rep(0,length(s))
         if (t>zi[length(zi)]) {res=0}
         else {res=intensity(t,zi,nknots,the,bZ)$survival/intensity(s,zi,nknots,the,bZ)$survival}
     }
    return(res)
}



lifexpect0.idmWeib <- function(s,a01,b01,a02,b02,a12,b12,bZ01=0,bZ02=0,bZ12=0,max) {
    ## print("lifexpect0.idmWeib")
    # max <- 100
    ET12 = integrate(
        f=function(x) {
            S.weib(s,x,a12,b12,bZ12)
        },s,max)
    ET0dot = integrate(f=function(x) {
        S.weib(s,x,a01,b01,bZ01)*S.weib(s,x,a02,b02,bZ02)
    },s,max)
    ET01 = integrate(f=function(x){
        sapply(x,function(x){
            integrate(f=function(y){
                S.weib(s,y,a01,b01,bZ01)*S.weib(s,y,a02,b02,bZ02)*iweibull(y,a01,b01,bZ01)*S.weib(y,x,a12,b12,bZ12)},
                lower=s,
                upper=x)$value})},s,max)
    LTR=integrate(f=function(x){
      S.weib(s,x,a01,b01,bZ01)*S.weib(s,x,a02,b02,bZ02)*iweibull(x,a01,b01,bZ01)},s,max)
    list(LE.00=ET0dot$value,
         LE.0.=ET01$value+ET0dot$value,
         LE.01=ET01$value,
         LE.11=ET12$value,
         LTR=LTR$value)

}

lifexpect0.idmPl <- function(s,knots01,nknots01,the01,knots12,nknots12,the12,knots02,nknots02,the02,bZ01=0,bZ12=0,bZ02=0) {
  ET12 = integrate(f=function(x) {
    S.pl(s,x,knots12,nknots12,the12,bZ12)},s,knots12[nknots12+6])
  ET0dot = integrate(f=function(x) {
    S.pl(s,x,knots01,nknots01,the01,bZ01)*S.pl(s,x,knots02,nknots02,the02,bZ02)  },s,knots02[nknots02+6])
  ET01 = integrate(f=function(x) {
    sapply(x,function(x) {integrate(f=function(y){
      (S.pl(s,y,knots01,nknots01,the01,bZ01)
       *S.pl(s,y,knots02,nknots02,the02,bZ02)*
         intensity(times=y,knots=knots01,number.knots=nknots01,theta=the01,linear.predictor=bZ01)$intensity
       *S.pl(y,x,knots12,nknots12,the12,bZ12))},
      lower=s,upper=x)$value})},s,knots01[nknots01+6])
  LTR=integrate(f = function(x) {S.pl(s, x, knots01, nknots01, the01, bZ01) * S.pl(s, x, knots02, nknots02, the02, bZ02) * intensity(times = x, knots = knots01, number.knots = nknots01, theta = the01,linear.predictor = bZ01)$intensity }, lower = s, upper = knots01[nknots01+6])$value
  list(LE.00=ET0dot$value,
       LE.0.=ET01$value+ET0dot$value,
       LE.01=ET01$value,
       LE.11=ET12$value,
       LTR=LTR)
}
