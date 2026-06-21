# Practice 4 – Statistical Analysis (Correlation & Regression)

**Course:** Data Analysis  
**Institution:** Irkutsk National Research Technical University, Baikal School of BRICS

---

## R Environment

| Item | Version |
|------|---------|
| R | 4.5.3 (2026-03-11 ucrt) "Reassured Reassurer" |
| Platform | x86_64-w64-mingw32/x64 (Windows) |
| Packages | `wPerm` (permutation tests), `pROC` (ROC/AUC) |

---

## Procedures

### 1 · Normality Assessment
- **Shapiro-Wilk test** on `hormone1`–`hormone4`
- Visual inspection: **histogram** and **Q-Q plot** for `hormone1`
- **Result:** all four variables significantly non-normal (W ≈ 0.38–0.73, p < 2.2×10⁻¹⁶)  
  → Spearman rank correlation selected

### 2 · Correlation Analysis
- Standard Spearman (`cor.test`, method = "spearman"): `hormone1` vs `hormone2`
- **Permutation-based Spearman** (`perm.relation`, R = 10 000): `hormone1` vs `hormone2`, `hormone3`, `hormone4`
- Spearman table: all four hormones vs `outcome`

### 3 · Regression Analysis – `hormone1 ~ hormone2`
Five model types compared by **BIC** (lower = better):

| Rank | Model | R² | BIC |
|------|-------|-----|-----|
| 1 | **Exponential** `log(hormone1) ~ hormone2` | 0.0119 | 2 074 |
| 2 | Linear | 0.0055 | 4 204 |
| 3 | Polynomial 2nd degree | 0.0114 | 4 204 |
| 4 | Polynomial 3rd degree | 0.0126 | 4 210 |
| 5 | Log-transform | 0.0000 | 55 115 |

**Best model:** exponential (log-linear)

### 4 · Logistic Regression

Three models:

| Model | Predictors | AIC | BIC |
|-------|-----------|-----|-----|
| model_logit_1 | hormone1 | 928.8 | 938.9 |
| **model_logit_2** | hormone1 + hormone2 | **927.9** | 943.0 |
| model_logit_all | hormone1–4 | 928.7 | 954.0 |


| Term | OR | 95% CI |
|------|----|--------|
| hormone1 | 0.894 | [0.755 – 1.024] |
| hormone2 | 1.001 | [1.000 – 1.001] |

Neither predictor reaches conventional significance (p < 0.05), though hormone2 shows a marginal trend (p = 0.073).

---

## Files

| File | Description |
|------|-------------|
| `data_for_analysis.csv` | Source dataset (1 148 obs × 31 vars) |
| `practice_4_task4.R` | Full R script (all analyses + comments) |
| `plot_histogram_qqplot_hormone1.png` | Histogram & Q-Q plot for hormone1 |
| `plot_scatter_hormone1_hormone2.png` | Scatter plot with linear fit (correlation visualisation) |
| `plot_regression_hormone1_hormone2.png` | Regression scatter plot with fitted linear line |
| `plot_ROC_curve.png` | ROC curve for model_logit_2 (AUC = 0.554) |
