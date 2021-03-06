% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PLNnetworkfamily-class.R
\name{PLNnetworkfamily_getBestModel}
\alias{PLNnetworkfamily_getBestModel}
\title{Best model extraction from a collection of PLNnetworkfit}
\arguments{
\item{crit}{a character for the criterion used to performed the selection. Either
"BIC", "EBIC", "StARS", "R_squared". Default is \code{BIC}. If StARS
(Stability Approach to Regularization Selection) is chosen and stability selection
 was not yet performed, the function will call the method stability_selection with default argument.}

\item{stability}{a scalar, indicating the target stability (= 1 - 2 beta) at which the network is selected. Default is \code{0.9}.}
}
\value{
Send back a object with class \code{\link[=PLNnetworkfit]{PLNnetworkfit}}.
}
\description{
Best model extraction from a collection of PLNnetworkfit
}
