% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods.R
\name{weights.nonprob}
\alias{weights.nonprob}
\title{Extracts the inverse probability weights}
\usage{
\method{weights}{nonprob}(object, ...)
}
\arguments{
\item{object}{a \code{nonprob} class object}

\item{...}{other arguments passed to methods (currently not supported)}
}
\value{
A vector of weights or a \code{NULL} extracted from the \code{nonprob} object i.e. element \code{"ipw_weights"}
}
\description{
A generic function \code{weights} that returns inverse probability weights (if present)
}
\examples{

data(admin)
data(jvs)

jvs_svy <- svydesign(ids = ~ 1,  weights = ~ weight,
strata = ~ size + nace + region, data = jvs)

ipw_est1 <- nonprob(selection = ~ region + private + nace + size,
target = ~ single_shift,
svydesign = jvs_svy,
data = admin, method_selection = "logit", se = FALSE
)

summary(weights(ipw_est1))

}
