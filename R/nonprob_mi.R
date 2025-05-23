#' @useDynLib nonprobsvy
#' @importFrom stats glm.fit
#' @importFrom stats model.frame
#' @importFrom stats model.matrix
#' @importFrom stats update
#' @importFrom stats qnorm
#' @importFrom stats weighted.mean
#' @importFrom stats var
#' @importFrom RANN nn2
#' @importFrom ncvreg cv.ncvreg
#' @importFrom stats terms
#' @importFrom stats reformulate
#' @importFrom survey svytotal
#' @import Rcpp
#' @importFrom Rcpp evalCpp
#' @noRd
nonprob_mi <- function(outcome,
                       data,
                       svydesign,
                       pop_totals,
                       pop_means,
                       pop_size,
                       method_outcome,
                       family_outcome,
                       strata,
                       case_weights,
                       na_action,
                       control_outcome,
                       control_inference,
                       start_outcome,
                       verbose,
                       se,
                       pop_size_fixed,
                       ...) {

  vars_selection <- control_inference$vars_selection
  outcome_init <- outcome
  outcomes <- make_outcomes(outcome)
  output <- list()

  outcome_method <- switch(method_outcome,
                          "glm" = method_glm,
                          "nn" = method_nn,
                          "pmm" = method_pmm,
                          "npar" = method_npar)

  ys_resid <- ys_rand_pred <- ys_nons_pred <- ys <- list()
  outcome_list <- list()

  if (se) {
    confidence_interval <- list()
    SE_values <- list()
  } else {
    confidence_interval <- NULL
    SE_values <- NULL
  }

  for (o in 1:outcomes$l) {

    outcome_model_data <- make_model_frame(formula = outcomes$outcome[[o]],
                                           data = data,
                                           weights = weights,
                                           svydesign = svydesign,
                                           pop_totals = pop_totals)

    X_nons <- outcome_model_data$X_nons
    X_rand <- outcome_model_data$X_rand
    nons_names <- outcome_model_data$nons_names
    y_nons <- outcome_model_data$y_nons
    pop_totals_ <- outcome_model_data$pop_totals ## match the same as in X_nons

    model_obj <- outcome_method(y_nons = y_nons,
                                X_nons = X_nons,
                                X_rand = X_rand,
                                svydesign = svydesign,
                                weights=case_weights,
                                family_outcome=family_outcome,
                                start_outcome=start_outcome,
                                vars_selection=vars_selection,
                                pop_totals=pop_totals_,
                                pop_size=pop_size,
                                control_outcome=control_outcome,
                                control_inference=control_inference,
                                verbose=verbose,
                                se=se)

    if (control_outcome$pmm_k_choice == "min_var" & method_outcome == "pmm") {
      # This can be programmed a lot better possibly with custom method outcome that would
      # store previous k-pmm model and omit the last estimation
      ## TODO:: right now this only goes forward not backwards
      var_prev <- Inf
      cond <- TRUE
      kk <- 0
      while (cond) {
        kk <- kk + 1
        control_outcome$k <- kk
        model_obj <- outcome_method(y_nons = y_nons,
                                    X_nons = X_nons,
                                    X_rand = X_rand,
                                    svydesign = svydesign,
                                    weights=case_weights,
                                    family_outcome=family_outcome,
                                    start_outcome=start_outcome,
                                    vars_selection=vars_selection,
                                    pop_totals=pop_totals_,
                                    pop_size=pop_size,
                                    control_outcome=control_outcome,
                                    control_inference=control_inference,
                                    verbose=verbose,
                                    se=TRUE)

        # variance
        var_now <- model_obj$var_total
        cond <- var_prev > var_now
        var_prev <- var_now
      }

      if (isTRUE(verbose)) {
        message(paste("The `k` that minimises variance of the `pmm` MI estimator is:", kk))
      }

      control_outcome$k <- kk
      model_obj <- outcome_method(y_nons = y_nons,
                                  X_nons = X_nons,
                                  X_rand = X_rand,
                                  svydesign = svydesign,
                                  weights=case_weights,
                                  family_outcome=family_outcome,
                                  start_outcome=start_outcome,
                                  vars_selection=vars_selection,
                                  pop_totals=pop_totals_,
                                  pop_size=pop_size,
                                  control_outcome=control_outcome,
                                  control_inference=control_inference,
                                  verbose=verbose,
                                  se=se)
    }


    mu_hat <- model_obj$y_mi_hat

    if (!is.null(svydesign)) svydesign <- model_obj$svydesign

    outcome_list[[o]] <- model_obj$model_fitted
    outcome_list[[o]]$model_frame <- outcome_model_data$model_frame_rand
    ys[[o]] <- as.numeric(y_nons)
    ys_rand_pred[[o]] <- model_obj$y_rand_pred
    ys_nons_pred[[o]] <- model_obj$y_nons_pred
    ys_resid[[o]] <- as.numeric(y_nons) - model_obj$y_nons_pred

    if (se) {

      if (control_inference$var_method == "bootstrap") {
        num_boot <- control_inference$num_boot
        stat_boot <- matrix(nrow = control_inference$num_boot, ncol = outcomes$l)
        var_comp2 <- matrix(nrow = control_inference$num_boot, ncol = outcomes$l)
      }

      if (control_inference$var_method == "analytic")  {
        var_nonprob <- model_obj$var_nonprob
        var_prob <- model_obj$var_prob
        var_total <- model_obj$var_total
        se_nonprob <- sqrt(var_nonprob)
        se_prob <- sqrt(var_prob)
        SE_values[[o]] <- data.frame(t(data.frame("SE" = c(prob = se_prob, nonprob = se_nonprob))))
        SE <- sqrt(var_total)
        alpha <- control_inference$alpha
        z <- stats::qnorm(1 - alpha / 2)
        # confidence interval based on the normal approximation
        confidence_interval[[o]] <- data.frame(lower_bound = mu_hat - z * SE,
                                               upper_bound = mu_hat + z * SE)
      } else {

        boot_obj <- boot_mi(model_obj=model_obj,
                            y_nons=y_nons,
                            X_nons=X_nons,
                            X_rand=X_rand,
                            case_weights=case_weights,
                            pop_totals=pop_totals_,
                            pop_size = pop_size,
                            family_outcome=family_outcome,
                            control_outcome=control_outcome,
                            control_inference=control_inference,
                            verbose = verbose)

        if (isTRUE(control_inference$nn_exact_se) & method_outcome %in% c("pmm", "nn")) {
          ## mini-bootstrap as suggested in the MI-PMM paper
          boot_obj_comp2 <- outcome_method(y_nons = y_nons,
                                           X_nons = X_nons,
                                           X_rand = X_rand,
                                           svydesign = svydesign,
                                           weights=case_weights,
                                           family_outcome=family_outcome,
                                           start_outcome=start_outcome,
                                           vars_selection=vars_selection,
                                           pop_totals=pop_totals_,
                                           pop_size=pop_size,
                                           control_outcome=control_outcome,
                                           control_inference=control_inference,
                                           verbose=verbose,
                                           se=se)

          comp2 <- boot_obj_comp2$var_nonprob
        } else {
          comp2 <- 0
        }

        var_total <- var(boot_obj) + comp2
        stat_boot[, o] <- boot_obj
        var_comp2[, o] <- comp2
        SE_values[[o]] <- data.frame(t(data.frame("SE" = c(nonprob = NA, prob = NA))))
        SE <- sqrt(var_total)
        alpha <- control_inference$alpha
        z <- stats::qnorm(1 - alpha / 2)
        # confidence interval based on the normal approximation
        confidence_interval[[o]] <- data.frame(lower_bound = mu_hat - z * SE,
                                               upper_bound = mu_hat + z * SE)
      }


    } else {
      SE <- NA
      confidence_interval[[o]] <- data.frame(lower_bound = NA, upper_bound = NA )
      SE_values[[o]] <- data.frame(nonprob = NA, prob = NA)
    }

    output[[o]] <- data.frame(mean = mu_hat, SE = SE)
    outcome_list[[o]]$method <- method_outcome
  }

  output <- do.call(rbind, output)
  confidence_interval <- do.call(rbind, confidence_interval)
  SE_values <- do.call(rbind, SE_values)
  rownames(output) <- rownames(confidence_interval) <- rownames(SE_values) <- outcomes$f
  names(outcome_list) <- outcomes$f
  names(ys) <- all.vars(outcome_init[[2]])

  boot_sample <- if (isTRUE(se) & control_inference$var_method == "bootstrap" & control_inference$keep_boot) {
    colnames(var_comp2) <- colnames(stat_boot) <- names(ys)
    list(stat = stat_boot, comp2 = var_comp2)
  } else {
    NULL
  }

  structure(
    list(
      data = data,
      X = rbind(X_nons, X_rand),
      y = ys,
      R = c(rep(1, NROW(X_nons)), rep(0, NROW(X_rand))),
      ps_scores = NULL,
      case_weights = case_weights,
      ipw_weights = NULL,
      control = list(
        control_selection = NULL,
        control_outcome = control_outcome,
        control_inference = control_inference
      ),
      output = output,
      SE = SE_values,
      confidence_interval = confidence_interval,
      nonprob_size = NROW(X_nons),
      prob_size = NROW(X_rand),
      pop_size = pop_size,
      pop_size_fixed = pop_size_fixed,
      pop_totals = pop_totals,
      pop_means = pop_means,
      outcome = outcome_list,
      selection = NULL,
      boot_sample = boot_sample,
      svydesign = svydesign,
      ys_rand_pred = ys_rand_pred,
      ys_nons_pred = ys_nons_pred,
      ys_resid = ys_resid
    ),
    class = "nonprob"
  )
}
