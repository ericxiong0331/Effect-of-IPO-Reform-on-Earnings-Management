# Effect-of-IPO-Reform-on-Earnings-Management
Causal Inference: Effect of Initial Public Offering Reform on Earnings Management

This repository provides data and Stata replication code for an empirical study on how China’s IPO registration system reform affects IPO firms’ post-listing performance reversal, measured by changes in profitability around the IPO year.

## Project overview

China gradually implemented the IPO registration system via pilots on the STAR Market (2019), ChiNext (2020), and the Beijing Stock Exchange (2021), before moving toward a fully registration-based regime. 
This project evaluates whether listing under the registration system reduces the severity of post-IPO performance drops using a difference-in-differences (DID) framework.

## Data

### Sample Description

- Population: A-share IPO firms listed between 2017-01-01 and 2022-12-31.
- Initial sample size: 2,128 IPO firms.
- Exclusions: financial industry firms (41) and observations with missing data (14).
- Final sample size: 2,073 firms.

### Data sources

Firm-level financial and market variables are collected from WIND and CSMAR.

### Variable definitions

**Outcomes (earnings “turning face” / performance deterioration):**
- ΔROA: change in return on assets from the year before listing to the listing year.
- ΔROE: change in return on equity from the year before listing to the listing year. 

**Treatment / policy variable:**
- `registration_m`: indicator equal to 1 if the firm is listed under the registration system, and 0 otherwise (constructed from treatment-group and post-policy timing). 

**Controls (used in regressions and matching):**
- Size, Lev, Mfee, Top1, Zindex, Sindex, Premium, VCPE, Age.

### Data processing

- Continuous variables are winsorized at the 1st and 99th percentiles (including ΔROA, ΔROE, and key controls).

## Methodology

### Baseline DID specification

The main regressions estimate the effect of `registration_m` on ΔROA and ΔROE while controlling for year and industry fixed effects, and adding standard firm-level controls.

### Identification and robustness

This repository replicates the paper’s main identification and robustness checks:

- **Parallel trends / event-study**: constructs event-time indicators relative to each board’s pilot year and plots dynamic coefficients.
- **Placebo test**: permutes the policy indicator and re-estimates 500 times to compare the simulated coefficient distribution with the baseline estimate. 
- **PSM-DID**: uses logit propensity score matching (1:1 nearest neighbor with caliper) based on the control variables, then re-estimates DID on the matched sample.

## How to run (Stata)

### Requirements

- Stata 18 for full compatibility with the workflow described in the paper.
- Commonly-used user-written packages referenced in the code include: `winsor2`, `outreg2`, `coefplot`, and `psmatch2`.

### Steps

1. Open Stata and set the working directory to the project folder.
2. Directly Run the `main.do` with `Startdata.dta` or export your data as .dta file first.

### What does the .do file produce

- Descriptive statistics outputs (summary.xlsx). 
- Baseline regression tables for ΔROA and ΔROE (基础回归.docx). 
- Parallel trends / dynamic effect plots (平行趋势检验.docx, parallel_test_roa.png, parallel_test_roe.png).
- Placebo-test coefficient distribution figures (安慰剂检验_roa.png, 安慰剂检验_roe.png).
- PSM diagnostics and PSM-DID regression outputs (截面匹配回归结果对比.docx, 逐年匹配回归结果对比.docx, balancing_assumption.emf, common_support.emf, kensity_cs_before.emf, kensity_cs_after.emf).

## Empirical Results

- The registration system reform is associated with significantly higher ΔROA and ΔROE (i.e., less post-IPO performance deterioration), and the baseline DID coefficients on the registration indicator are positive and statistically significant.
- Dynamic (event-study) results suggest the policy effect strengthens in the years after the pilot implementation.
- Placebo tests and PSM-DID analyses support the robustness of the baseline conclusion.
