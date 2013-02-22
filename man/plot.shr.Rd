\name{plot.shr}
\alias{plot.shr}

\title{
Plot method for a survival model.
}
\description{
  Plot estimated baseline survival function from an object of class \code{shr}. Confidence bands are allowed. 
}
\usage{

\method{plot}{shr}(x, type="shr", add = FALSE, newdata=NULL, cause=NULL, col, lty, lwd,
	ylim, xlim, xlab="Time" ,ylab, legend=TRUE, confint=TRUE, timeOrigin=0,
	axes=TRUE, percent=TRUE,...)
}
\arguments{
  \item{x}{a \code{shrWeib} or a \code{shrPl} class object (output from calling \code{\link{shr}}
    function).
}
  \item{type}{type of function to plot. The default is "shr".
} 
  \item{add}{boolean.
}
  \item{newdata}{newdata.
}
  \item{cause}{cause.
}
  \item{col}{col.
}
  \item{lty}{lty.
}
  \item{lwd}{lwd.
}
  \item{ylim}{ylim.
}
  \item{xlim}{xlim.
}
  \item{xlab}{xlab.
}
  \item{ylab}{ylab.
}
  \item{legend}{legend.
}
  \item{confint}{confint.
}
  \item{timeOrigin}{timeOrigin.
}
  \item{axes}{axes.
}
  \item{percent}{percent.
}
  \item{\dots}{other graphical parameters.}
}


\value{
     Print a plot of a suvival model.
}

\seealso{
\code{\link{plot.shr}}
}

\author{
R: Celia Touraine <Celia.Touraine@isped.u-bordeaux2.fr>
Fortran: Pierre Joly <Pierre.Joly@isped.u-bordeaux2.fr>

}

\examples{
\dontrun{
# Weibull survival model 
data(test)
fit.su <- shr(Hist(time=list(l,r),id)~cov,data=test) 

# confidence bands
plot(fit.su)

# no confidence bands
plot(fit.su,confint=FALSE)

}
}

\keyword{methods}
