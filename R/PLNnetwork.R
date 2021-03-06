##' @title Fit a Poisson lognormal model towards network inference
##'
##' @description two methods are available for specifying the models (with formulas or matrices)
##'
##' @param Robject an R object, either a formula or a (n x p) matrix of count data
##' @param X an optional (n x d) matrix of covariates. A vector of intercept is included by default. Ignored when Robject is a formula.
##' @param O an optional (n x p) matrix of offsets. Ignored when Robject is a formula.
##' @param penalties an optional vector of positive real number controling the level of sparisty of the underlying network. if NULL (the default), will be set internally
##' @param control.init a list for controling the optimization at initialization. See details.
##' @param control.main a list for controling the main optimization process. See details.
##' @param ... additional parameters for S3 compatibility. Not used
##'
##' @return an R6 object with class \code{\link[=PLNnetworkfamily]{PLNnetworkfamily}}, which contains
##' a collection of models with class \code{\link[=PLNnetworkfit]{PLNnetworkfit}}
##'
##' @details The list of parameters \code{control.init} and \code{control.main} control the optimization of the initialization and the main process.
##'
##'  The following entries are shared by both \code{control.init} and \code{control.main} and mainly concern the optimization parameters of NLOPT. There values can be different in \code{control.init} and \code{control.main}
##'  \itemize{
##'  \item{"ftol_rel"}{stop when an optimization step changes the objective function by less than ftol_rel multiplied by the absolute value of the parameter.}
##'  \item{"ftol_abs"}{stop when an optimization step changes the objective function by less than ftol_abs .}
##'  \item{"xtol_rel"}{stop when an optimization step changes every parameters by less than xtol_rel multiplied by the absolute value of the parameter.}
##'  \item{"xtol_abs"}{stop when an optimization step changes every parameters by less than xtol_abs.}
##'  \item{"maxeval"}{stop when the number of iteration exceeds maxeval. Default is 10000}
##'  \item{"method"}{the optimization method used by NLOPT among LD type, i.e. "MMA", "LBFGS",
##'     "TNEWTON", "TNEWTON_RESTART", "TNEWTON_PRECOND", "TNEWTON_PRECOND_RESTART",
##'     "VAR1", "VAR2". See NLOPTR documentation for further details. Default is "MMA".}
##'  \item{"trace"}{integer for verbosity. Useless when \code{cores} > 1}
##' }
##'
##' The following parameter are specific to initialization
##' \itemize{
##'  \item{"inception"}{a PLNfit to start with. If NULL, a PLN is fitted. If an R6 object with class 'PLNfit' is given, it is used to initialize the model.}
##'  \item{"nPenalties"}{an integer that specified the number of values for the penalty grid when internally generated. Ignored when penalties is non NULL}
##'  \item{"min.ratio"}{the penalty grid ranges from the minimal value that produces a sparse to this value multiplied by \code{min.ratio}. Default is 0.01 for high dimensional problem, 0.001 otherwise.}
##' }
##'
##' The following parameter are specific to main iterative process
##' \itemize{
##'  \item{"ftol_out"}{outer solver stops when an optimization step changes the objective function by less than xtol multiply by the absolute value of the parameter. Default is 1e-6}
##'  \item{"maxit_out"}{outer solver stops when the number of iteration exceeds out.maxit. Default is 50}
##'  \item{"penalize.diagonal"}{boolean: should the diagonal terms be penalized in the graphical-Lasso? Default is FALSE.}
##' }
##'
##' @rdname PLNnetwork
##' @examples
##' ## See the vignette
##' @seealso The classes \code{\link[=PLNnetworkfamily]{PLNnetworkfamily}} and \code{\link[=PLNnetworkfit]{PLNnetworkfit}}
##' @importFrom stats model.frame model.matrix model.response model.offset
##' @export
PLNnetwork <- function(Robject, ...) UseMethod("PLNnetwork", Robject)

##' @rdname PLNnetwork
##' @export
PLNnetwork.formula <- function(Robject, penalties = NULL, control.init = list(), control.main = list(), ...) {

  formula <- Robject
  frame  <- model.frame(formula)
  Y      <- model.response(frame)
  X      <- model.matrix(formula)
  O      <- model.offset(frame)
  if (is.null(O)) O <- matrix(0, nrow(Y), ncol(Y))

  return(PLNnetwork.default(Y, X, O, penalties, control.init, control.main))
}

##' @rdname PLNnetwork
##' @export
PLNnetwork.default <- function(Robject, X = NULL, O = NULL, penalties = NULL,
                               control.init = list(), control.main=list(), ...) {

  Y <- as.matrix(Robject); rm(Robject) # no copy made
  ## problem dimensions
  n  <- nrow(Y); p <- ncol(Y)
  if (is.null(X)) X <- matrix(1, n, 1)
  if (is.null(O)) O <- matrix(0, n, p)

  ## define default control parameters for optim and overwrite by user defined parameters
  ctrl.init <- PLNnetwork_param(control.init, n, p, "init")
  ctrl.main <- PLNnetwork_param(control.main, n, p, "main")

  ## Instantiate the collection of PLN models
  if (ctrl.main$trace > 0) cat("\n Initialization...")
  myPLN <- PLNnetworkfamily$new(penalties = penalties, responses = Y, covariates = X, offsets = O, control = ctrl.init)

  ## Main optimization
  if (ctrl.main$trace > 0) cat("\n Adjusting", length(myPLN$penalties), "PLN with sparse inverse covariance estimation\n")
  if (ctrl.main$trace) cat("\tJoint optimization alternating gradient descent and graphical-lasso\n")
  myPLN$optimize(ctrl.main)

  ## Post-treatments: compute pseudo-R2
  if (ctrl.main$trace > 0) cat("\n Post-treatments")
  myPLN$postTreatment()

  if (ctrl.main$trace > 0) cat("\n DONE!\n")
  return(myPLN)
}
