# Bank-Loan-Recommendation-Tool

This tool grades loan applications using historical loan data. It calculates Debt-to-Income (DTI), derives purpose-specific thresholds, assigns a grade (A–G), and provides a recommendation with similar-loan comparisons.

Project has been refactored into a clean, testable module structure.

Structure
- src/BankLoanRecommendationTool.jl: Module entry, exports
- src/data.jl: Data loading and normalization
- src/grading.jl: DTI calc, threshold derivation, grade assignment
- src/formatting.jl: Currency/number formatting and table printing
- src/similarity.jl: Similar loans by DTI
- src/reporting.jl: Recommendation text
- src/main.jl: CLI entry (interactive)
- data/loan_data.csv: Sample dataset
- docs/: Reference materials
- examples/bank_loan_advisor_legacy.jl: Archived legacy script
- test/: Minimal unit tests for each module

Setup
- Optional: Install deps (Project.toml provided):
  - julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
  - Note: src/main.jl will auto-activate the project and install CSV/DataFrames if missing.

Run (CLI)
- Easiest (one file):
  - julia run.jl
- Or directly:
  - julia --project src/main.jl
- When prompted, press Enter to use the included data/loan_data.csv or provide a custom CSV path.

Run Tests
- From repo root:
  - julia --project test/runtests.jl

CSV Expectations
- Required columns (case-insensitive names are normalized):
  - annual_income, loan_amount (or loan_dollar_amount), term, purpose, grade, dti (or debt_to_income_ratio)
- Optional columns used for reporting if present:
  - monthly_installment (from installment), int_rate, total_accounts (from total_acc)
- The loader normalizes: purpose → lowercase, grade → uppercase, computes debt_to_income_ratio if missing.

Notes
- Older exploratory scripts have been deprecated in favor of the new modules and tests.
