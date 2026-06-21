data <- read.csv("data_for_analysis.csv")
data$outcome <- as.factor(data$outcome)
summary(data)

# Shapiro-Wilk test (n < 5000 requirement met)
shapiro.test(data$hormone1)  # W = 0.579, p < 2.2e-16 -> non-normal
shapiro.test(data$hormone2)  # W = 0.732, p < 2.2e-16 -> non-normal
shapiro.test(data$hormone3)  # W = 0.576, p < 2.2e-16 -> non-normal
shapiro.test(data$hormone4)  # W = 0.383, p < 2.2e-16 -> non-normal

# Conclusion: all hormone variables are significantly non-normally distributed
# -> Spearman rank correlation is the appropriate method

# Visual check: histogram + Q-Q plot for hormone1
par(mfrow = c(1, 2))
hist(data$hormone1, main = "Histogram: hormone1",
     col = "lightblue", xlab = "hormone1")
qqnorm(data$hormone1, main = "Q-Q Plot: hormone1")
qqline(data$hormone1, col = "red", lwd = 2)
par(mfrow = c(1, 1))
# -> Save as: plot_histogram_qqplot_hormone1.png

# Standard Spearman: hormone1 vs hormone2
spearman_result <- cor.test(data$hormone1, data$hormone2, method = "spearman")
print(spearman_result)
# rho = 0.175, p = 2.35e-09 -> significant positive correlation

# --- Permutation-based Spearman (wPerm package) ---
# More reliable with tied values and non-normal data
# R = 10000 permutations
if (!require(wPerm)) install.packages("wPerm")
library(wPerm)

results <- data.frame(
  variable     = character(),
  spearman_rho = numeric(),
  perm_p_value = numeric(),
  stringsAsFactors = FALSE
)

target_vars <- c("hormone2", "hormone3", "hormone4")

for (var in target_vars) {
  perm_res <- perm.relation(
    x      = data$hormone1,
    y      = data[[var]],
    method = "spearman",
    R      = 10000
  )
  results <- rbind(results, data.frame(
    variable     = var,
    spearman_rho = perm_res$Observed,
    perm_p_value = perm_res$p.value
  ))
}

cat("\n=== PERMUTATION-BASED SPEARMAN CORRELATIONS (hormone1 vs) ===\n")
print(results)
# Results:
#   hormone2: rho =  0.175, p = 0.0002  -> SIGNIFICANT
#   hormone3: rho = -0.007, p = 0.816   -> not significant
#   hormone4: rho =  0.018, p = 0.529   -> not significant

# Standard Spearman table: all hormones vs outcome
cat("\n=== STANDARD SPEARMAN: hormones vs outcome ===\n")
data_num <- data
data_num$outcome_num <- as.numeric(as.character(data_num$outcome))
corr_table <- data.frame(variable = character(), rho = numeric(), p_value = numeric())
for (v in c("hormone1","hormone2","hormone3","hormone4")) {
  res <- cor.test(data_num$outcome_num, data_num[[v]],
                  method = "spearman", use = "complete.obs")
  corr_table <- rbind(corr_table, data.frame(
    variable = v,
    rho      = round(res$estimate, 4),
    p_value  = round(res$p.value, 6)
  ))
}
print(corr_table)
# hormone2 shows significant association with outcome (rho=0.082, p=0.005)

data_sorted <- data[order(data$hormone2), ]
plot(data_sorted$hormone2, data_sorted$hormone1,
     main = "hormone1 vs hormone2",
     xlab = "hormone2", ylab = "hormone1",
     pch = 16, col = "steelblue", cex = 0.6)
lines(data_sorted$hormone2, data_sorted$hormone1, col = "lightgray")
abline(lm(hormone1 ~ hormone2, data = data_sorted), col = "red", lwd = 2)
legend("topleft", legend = "Linear fit", col = "red", lwd = 2)
# -> Save as: plot_scatter_hormone1_hormone2.png

df <- data[order(data$hormone2), ]

model_linear <- lm(hormone1 ~ hormone2,          data = df)
model_2      <- lm(hormone1 ~ poly(hormone2, 2), data = df)
model_3      <- lm(hormone1 ~ poly(hormone2, 3), data = df)
model_exp    <- lm(log(hormone1) ~ hormone2,     data = df)  # exponential
model_log    <- lm(exp(hormone1) ~ hormone2,     data = df)  # log-transform

# BIC model comparison (lower = better)
bic_table <- data.frame(
  model = c("linear","poly2","poly3","exponential","log_transform"),
  R2    = c(summary(model_linear)$r.squared,
            summary(model_2)$r.squared,
            summary(model_3)$r.squared,
            summary(model_exp)$r.squared,
            summary(model_log)$r.squared),
  BIC   = c(BIC(model_linear), BIC(model_2), BIC(model_3),
            BIC(model_exp),    BIC(model_log))
)
bic_table <- bic_table[order(bic_table$BIC), ]
cat("\n=== BIC MODEL COMPARISON ===\n")
print(bic_table)
cat("Best model (lowest BIC):", bic_table$model[1], "\n")
# exponential: BIC = 2074 (best), R² = 0.012

cat("\n=== BEST MODEL SUMMARY (exponential: log(hormone1) ~ hormone2) ===\n")
print(summary(model_exp))

# Visualization with linear fit
plot(df$hormone2, df$hormone1,
     main = "Regression: hormone1 ~ hormone2",
     xlab = "hormone2", ylab = "hormone1",
     pch = 16, col = "gray60", cex = 0.6)
lines(df$hormone2, fitted(model_linear), col = "blue", lwd = 2)
legend("topright",
       legend = paste("Linear  R² =", round(summary(model_linear)$r.squared, 4)),
       col = "blue", lwd = 2)
# -> Save as: plot_regression_hormone1_hormone2.png

data <- data[!is.na(data$outcome), ]

# Three models with increasing complexity
model_logit_1   <- glm(outcome ~ hormone1,
                        data = data, family = binomial)
model_logit_2   <- glm(outcome ~ hormone1 + hormone2,
                        data = data, family = binomial)
model_logit_all <- glm(outcome ~ hormone1 + hormone2 + hormone3 + hormone4,
                        data = data, family = binomial)

# AIC / BIC comparison
cat("\n=== LOGISTIC REGRESSION MODEL COMPARISON ===\n")
comp <- data.frame(
  Model = c("model_logit_1","model_logit_2","model_logit_all"),
  AIC   = c(AIC(model_logit_1), AIC(model_logit_2), AIC(model_logit_all)),
  BIC   = c(BIC(model_logit_1), BIC(model_logit_2), BIC(model_logit_all))
)
print(comp)
# model_logit_2 has lowest AIC (927.87); model_logit_1 lowest BIC (938.92)

cat("\n--- Summary: model_logit_2 ---\n")
print(summary(model_logit_2))

cat("\n--- Summary: model_logit_all ---\n")
print(summary(model_logit_all))

# Predicted probabilities + classification (threshold = 0.5)
data$pred_prob  <- predict(model_logit_2, type = "response")
data$pred_class <- ifelse(data$pred_prob > 0.5, 1, 0)

cat("\n=== CONFUSION MATRIX (model_logit_2, threshold = 0.5) ===\n")
print(table(Actual = data$outcome, Predicted = data$pred_class))
# All predicted as 0 -> model struggles due to class imbalance (987:160)

# ROC curve & AUC
if (!require(pROC)) install.packages("pROC")
library(pROC)
roc_obj <- roc(data$outcome, data$pred_prob)
plot(roc_obj,
     main = "ROC Curve – model_logit_2",
     col = "steelblue", lwd = 2, print.auc = TRUE)
cat("\nAUC:", round(auc(roc_obj), 4), "\n")
# AUC = 0.5542 -> weak discriminative ability
# -> Save as: plot_ROC_curve.png

# Stepwise variable selection (AIC criterion, both directions)
cat("\n=== STEPWISE VARIABLE SELECTION ===\n")
step_model <- step(model_logit_all, direction = "both")
cat("Final formula:", deparse(formula(step_model)), "\n")
print(summary(step_model))
# Final: outcome ~ hormone1 + hormone2 + hormone4  (AIC = 926.72)

# Odds ratios + 95% CI for model_logit_2
cat("\n=== ODDS RATIOS (model_logit_2) ===\n")
print(exp(cbind(OR = coef(model_logit_2), confint(model_logit_2))))
# hormone1: OR = 0.894 [0.755–1.024] -> slight protective effect, not significant
# hormone2: OR = 1.001 [1.000–1.001] -> marginal positive effect

cat("\n========================================================\n")
cat("TASK 4 – RESULTS SUMMARY\n")
cat("========================================================\n")
cat("1. NORMALITY: all 4 hormone variables non-normal (Shapiro-Wilk p < 2.2e-16)\n")
cat("   -> Spearman correlation chosen\n\n")
cat("2. CORRELATION (permutation Spearman, hormone1 vs):\n")
print(results)
cat("   Only hormone2 shows significant correlation with hormone1 (rho=0.175, p=0.0002)\n\n")
cat("3. REGRESSION (hormone1 ~ hormone2), BIC ranking:\n")
print(bic_table)
cat("   Best model: exponential (log(hormone1) ~ hormone2), BIC=2074, R²=0.012\n")
cat("   Note: R² is very low -> hormone2 explains only ~1.2% of hormone1 variance\n\n")
cat("4. LOGISTIC REGRESSION (outcome ~ hormones):\n")
print(comp)
cat("   Stepwise final model: outcome ~ hormone1 + hormone2 + hormone4\n")
cat("   AUC =", round(auc(roc_obj), 4), "-> weak predictive performance\n")
cat("   Class imbalance (987 vs 160) limits model effectiveness\n")
