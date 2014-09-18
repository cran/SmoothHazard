\name{simulateIDM}
\alias{simulateIDM}
\title{Sample illness-death model data}
\usage{
simulateIDM(n = 100)
}
\arguments{
  \item{n}{number of observations}
}
\description{
Simulate data from an illness-death model with interval
censored event times and covariates
}
\details{
Simulate data from an illness-death model with interval
censored event times and covariates for the purpose of
illustrating the help pages of the SmoothHazard package.
See the body of the function for details, i.e., evaluate
simulateIDM
}
\examples{
simulateIDM
simulateIDM(100)
}
\seealso{
idmModel sim.idmModel
}
