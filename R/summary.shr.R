#' Summary of a fitted survival model using a penalized likelihood approach
#' 
#' Print a short summary of a fitted illness-death model using the penalized
#' likelihood approach.
#' 
#' 
#' @param object a \code{shr} object, i.e., the result of a call to the
#' \link{shr} function.
#' @param conf.int The level of confidence for the hazard ratios. The default is \code{0.95}.
#' @param digits number of digits to print.
#' @param pvalDigits number of digits to print for p-values.
#' @param eps convergence criterion used for p-values.
#' @param \dots other unusued arguments.
#' @author Celia Touraine <Celia.Touraine@@isped.u-bordeaux2.fr>
#' @seealso \link{shr}, \link{print.shr},
#' \link{plot.shr}
#' @keywords methods
#' @return No return value.
#' @examples
#' 
#' \donttest{
#' # a penalized survival model 
#' data(testdata)
#' library(prodlim)
#' fit.su <- shr(Hist(time=list(l,r),id)~cov,data=testdata,method="Splines") 
#' summary(fit.su)
#'
#' # Weibull survival model 
#' data(testdata)
#' fit.su <- shr(Hist(time=list(l,r),id)~cov,data=testdata) 
#' summary(fit.su) 
#' }
#' @export
summary.shr <- function(object,conf.int=.95,digits=4,pvalDigits=4,eps=.0001, ...){
    if (!inherits(object,"shr")) stop("Object must be of class 'shr'")
    if (object$method=="Weib"){
        x <- object
        if (x$converged[1] == 1){
            cat("Suvival model using a parametrical Weibull hazard function.\n")
            cat("\n")
            cat("number of subjects: ", x$N,"\n")
            cat("number of events: ", x$events,"\n")
            cat("number of covariates: ", x$NC,"\n")
            if(length(x$na.action))cat("observation deleted due to missing: ",length(x$na.action),"\n")
            if((x$NC>0)&&(x$converged[2]==1)){
                wald <- (x$coef/x$se)**2
                z <- abs(qnorm((1 + conf.int)/2))
                out <- data.frame("Hazard ratio"=format(round(exp(x$coef),digits)),
                                  "Standard error"=format(round(x$se,digits)),
                                  "CI"=paste("[",format(round(exp(x$coef - z * x$se),2)),";",format(round(exp(x$coef + z * x$se),2)),"]",sep=""),
                                  "P-value"=format.pval(1 - pchisq(wald, 1),digits=pvalDigits,eps=eps))
                names(out)[3] <- paste("CI",round(100*conf.int),sep=".")
                rownames(out) <- names(x$coef)
                print(out,row.names=T)
            }
        }
    }else{
    	x <- object
        #	if (x$istop == 1){
	if (x$converged[1] == 1){
            cat("Survival model using a Penalized Likelihood on the hazard function.\n")
            cat("\n")
            cat("number of subject: ", x$N,"\n")
            cat("number of covariates: ", x$NC,"\n")
            if(length(x$na.action))cat("observation deleted due to missing: ",length(x$na.action),"\n")

            if((x$NC>0)&&(x$converged[2]==1)){
                wald <- (x$coef/x$se)**2
                z <- abs(qnorm((1 + conf.int)/2))
                out <- data.frame("Hazard ratio"=format(round(exp(x$coef),digits)),
                                  "Standard error"=format(round(x$se,digits)),
                                  "CI"=paste("[",format(round(exp(x$coef - z * x$se),2)),";",format(round(exp(x$coef + z * x$se),2)),"]",sep=""),
                                  "P-value"=format.pval(1 - pchisq(wald, 1),digits=pvalDigits,eps=eps))
                names(out)[3] <- paste("CI",round(100*conf.int),sep=".")
                rownames(out) <- names(x$coef)
                print(out,row.names=TRUE)
            }
        }
    }
    return(NULL)
}
    
