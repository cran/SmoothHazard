% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/intensity.R
\name{intensity}
\alias{intensity}
\title{M-spline estimate of the transition intensity function}
\usage{
intensity(times, knots, number.knots, theta, linear.predictor = 0)
}
\arguments{
\item{times}{Time points at which to estimate the intensity function}

\item{knots}{Knots for the M-spline}

\item{number.knots}{Number of knots for the M-splines (and I-splines see details)}

\item{theta}{The coefficients for the linear combination of M-splines (and I-splines see details)}

\item{linear.predictor}{Linear predictor beta*Z. When it is non-zero, 
transition and cumulative transition are multiplied by \code{exp(linear.predictor)}. Default is zero.}
}
\value{
\item{times}{The time points at which the following estimates are evaluated.}
\item{intensity}{The transition intensity function evaluated at \code{times}.}
\item{cumulative.intensity}{The cumulative transition intensity function evaluated at \code{times}}
\item{survival}{The "survival" function, i.e., exp(-cumulative.intensity)}
}
\description{
M-spline estimate of the transition intensity function
and the cumulative transition intensity function
for survival and illness-death models
}
\details{
The estimate of the transition intensity function is a linear
combination of M-splines and the estimate of the cumulative transition
intensity function is a linear combination of I-splines (the integral of a
M-spline is called I-spline). The coefficients \code{theta} are the same for
the M-splines and I-splines.

Important: the theta parameters returned by \code{idm} and \code{shr} are in fact
the square root of the splines coefficients. See examples.

This function is a R-translation of a corresponding Fortran function called \code{susp}. \code{susp} is
used internally by \code{idm} and \code{shr}.
}
\examples{
data(testdata)
fit.su <- shr(Hist(time=list(l, r), id) ~ cov,
              data = testdata,method = "Splines",CV = TRUE)
intensity(times = fit.su$time, knots = fit.su$knots,
           number.knots = fit.su$nknots, theta = fit.su$theta^2)

\donttest{
  data(Paq1000)
  fit.idm <-  idm(formula02 = Hist(time = t, event = death, entry = e) ~ certif,
                  formula01 = Hist(time = list(l,r), event = dementia) ~ certif,
                  formula12 = ~ certif, method = "Splines", data = Paq1000)
  # Probability of survival in state 0 at age 80 for a subject with no cep given
  # that he is in state 0 at 70
  su0 <- (intensity(times = 80, knots = fit.idm$knots01, 
                   number.knots = fit.idm$nknots01, 
                   theta = fit.idm$theta01^2)$survival
         *intensity(times = 80, knots = fit.idm$knots02, 
                   number.knots = fit.idm$nknots02, 
                   theta = fit.idm$theta02^2)$survival)/
        (intensity(times = 70, knots = fit.idm$knots01, 
                   number.knots = fit.idm$nknots01, 
                   theta = fit.idm$theta01^2)$survival
        *intensity(times = 70, knots = fit.idm$knots02, 
                   number.knots = fit.idm$nknots02, 
                   theta = fit.idm$theta02^2)$survival)
  # Same result as:  
  predict(fit.idm, s = 70, t = 80, conf.int = FALSE) # see first element               
}
}
\seealso{
\link{shr}, \link{idm}
}
\author{
R: Celia Touraine <Celia.Touraine@isped.u-bordeaux2.fr> and Thomas Alexander Gerds <tag@biostat.ku.dk>
Fortran: Pierre Joly <Pierre.Joly@isped.u-bordeaux2.fr>
}
