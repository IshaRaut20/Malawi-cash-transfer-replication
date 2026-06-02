# Malawi-cash-transfer-replication
Replication of Baird, McIntosh & Özler (2011) — estimating marriage effects of conditional vs unconditional cash transfers in Malawi using OLS and panel methods
### Replicating the Marriage Effects of Conditional and Unconditional Cash Transfers

**Author:** Isha Raut | Boston University — MSc in Economic Policy and Practice  
**Course:** DS 925: Causal Inference  
**Date:** December 2025

---

## Research Question

Do conditional and unconditional cash transfers reduce early marriage among adolescent girls in low-income settings?

This project replicates **Table VII (Columns 1 & 2)** from Baird, McIntosh & Özler (2011) — one of the most cited RCTs in development economics — using publicly available data from the Schooling, Income and Health Risk (SIHR) study in Malawi.

---

## Background

The original study ran a large randomized controlled trial assigning schoolgirls and recent dropouts in Malawi to one of three groups:
- **CCT** — Conditional Cash Transfer (tied to school attendance)
- **UCT** — Unconditional Cash Transfer
- **Control** — No transfer

The authors found that both transfer programs reduced early marriage, with the conditional program having the stronger effect. Early marriage matters because it limits schooling and shapes long-term welfare outcomes for girls in low-income settings.

---

## Data

- **Source:** World Bank Microdata Library — Schooling, Income and Health Risk (SIHR) Survey, Malawi
- **Waves:** 2007 baseline, 2008 Round 2, 2010 Round 3
- **Sample:** 1,505 eligible girls at baseline → 1,438 in Round 2 → 1,422 in Round 3
- **Note:** Sample is smaller than the original (~2,400 girls) due to identifier structure differences in public use files

---

## Methodology

- OLS regression with sampling weights
- Cluster standard errors at the enumeration area (EA) level
- Controls: age indicators, baseline grade, female household head, strata fixed effects
- Outcome: Binary indicator for ever married by Round 2 / Round 3
- Heterogeneity analysis: Young (ages 13–15) vs. Older (ages 16–22)

---

## Key Results

| Outcome | CCT Effect | UCT Effect | N |
|---|---|---|---|
| Ever Married — Round 2 | -0.015 (p=0.590) | +0.001 (p=0.948) | 1,438 |
| Ever Married — Round 3 | **-0.178*** (p<0.001) | -0.036 (p=0.240) | 1,422 |

**Key finding:** Conditional transfers significantly reduced early marriage by Round 3. The CCT and UCT effects differ significantly from each other (F-test p<0.001 in Round 3).

### Comparison with Original Study

| | Original (Baird et al. 2011) | This Replication |
|---|---|---|
| CCT effect — Round 3 | -0.048 | -0.178 |
| UCT effect — Round 3 | Not significant | Not significant |
| Direction | Same ✅ | |
| Significance | Same ✅ | |

Effect sizes differ due to: a smaller replication sample sizes, differences in available baseline controls, and limits of public-use identifier matching.

---

## Files
malawi-cash-transfer-replication/
├── code/
│   └── replication.do        ← Stata do-file
├── output/
│   └── table2_marriage.rtf   ← Regression output table
└── report/
└── Malawi_Replication.pdf ← Full paper
---

## Policy Implications

Cash transfers — particularly conditional ones — can meaningfully delay early marriage among adolescent girls. The stronger CCT effect suggests that the school attendance condition itself, not just the income transfer, drives behavioral change. These findings have implications for program design in contexts where early marriage and school dropout are interlinked.

---

## Reference

Baird, S., McIntosh, C., & Özler, B. (2011). Cash or Condition? Evidence from a Cash Transfer Experiment. *Quarterly Journal of Economics*, 126(4), 1709–1753.
