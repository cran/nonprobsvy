// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <RcppArmadillo.h>
#include <Rcpp.h>

using namespace Rcpp;

#ifdef RCPP_USE_GLOBAL_ROSTREAM
Rcpp::Rostream<true>&  Rcpp::Rcout = Rcpp::Rcpp_cout_get();
Rcpp::Rostream<false>& Rcpp::Rcerr = Rcpp::Rcpp_cerr_get();
#endif

// cv_nonprobsvy_rcpp
Rcpp::List cv_nonprobsvy_rcpp(const arma::mat& X, const arma::vec& R, const arma::vec& weights_X, const std::string& method_selection, const int& h, int maxit, double eps, double lambda_min, int nlambda, int nfolds, const std::string& penalty, double a, Nullable<arma::vec> pop_totals, bool verbose, double lambda);
RcppExport SEXP _nonprobsvy_cv_nonprobsvy_rcpp(SEXP XSEXP, SEXP RSEXP, SEXP weights_XSEXP, SEXP method_selectionSEXP, SEXP hSEXP, SEXP maxitSEXP, SEXP epsSEXP, SEXP lambda_minSEXP, SEXP nlambdaSEXP, SEXP nfoldsSEXP, SEXP penaltySEXP, SEXP aSEXP, SEXP pop_totalsSEXP, SEXP verboseSEXP, SEXP lambdaSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< const arma::mat& >::type X(XSEXP);
    Rcpp::traits::input_parameter< const arma::vec& >::type R(RSEXP);
    Rcpp::traits::input_parameter< const arma::vec& >::type weights_X(weights_XSEXP);
    Rcpp::traits::input_parameter< const std::string& >::type method_selection(method_selectionSEXP);
    Rcpp::traits::input_parameter< const int& >::type h(hSEXP);
    Rcpp::traits::input_parameter< int >::type maxit(maxitSEXP);
    Rcpp::traits::input_parameter< double >::type eps(epsSEXP);
    Rcpp::traits::input_parameter< double >::type lambda_min(lambda_minSEXP);
    Rcpp::traits::input_parameter< int >::type nlambda(nlambdaSEXP);
    Rcpp::traits::input_parameter< int >::type nfolds(nfoldsSEXP);
    Rcpp::traits::input_parameter< const std::string& >::type penalty(penaltySEXP);
    Rcpp::traits::input_parameter< double >::type a(aSEXP);
    Rcpp::traits::input_parameter< Nullable<arma::vec> >::type pop_totals(pop_totalsSEXP);
    Rcpp::traits::input_parameter< bool >::type verbose(verboseSEXP);
    Rcpp::traits::input_parameter< double >::type lambda(lambdaSEXP);
    rcpp_result_gen = Rcpp::wrap(cv_nonprobsvy_rcpp(X, R, weights_X, method_selection, h, maxit, eps, lambda_min, nlambda, nfolds, penalty, a, pop_totals, verbose, lambda));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_nonprobsvy_cv_nonprobsvy_rcpp", (DL_FUNC) &_nonprobsvy_cv_nonprobsvy_rcpp, 15},
    {NULL, NULL, 0}
};

RcppExport void R_init_nonprobsvy(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}