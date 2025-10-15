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
- Clone and install dependencies
  - git clone https://github.com/<your-account>/Bank-Loan-Recommendation-Tool.git
  - cd Bank-Loan-Recommendation-Tool
  - julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
  - Dependencies: CSV, DataFrames, PrettyTables
  - The project has a valid Project.toml (name/uuid) so `using BankLoanRecommendationTool` works after `] activate .`.
  - Note: src/main.jl will also attempt to bootstrap core deps if missing.
  - No-preinstall fallback: If PrettyTables is not installed and you run files directly, the app will fall back to a simple ASCII table so it still runs.

Quick Start
- Unix/macOS
  - julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
  - julia run.jl
- Windows (PowerShell)
  - julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate()"
  - julia run.jl

Run (CLI)
- Option A: one-file launcher
  - julia run.jl
- Option B: as a package entry
  - julia --project=.
  - julia> using BankLoanRecommendationTool
  - julia> BankLoanRecommendationTool.start()
- Option C: run the CLI source directly
  - julia --project=. src/main.jl
- Tip (VS Code): If prompts are skipped on first run, set BLRT_ALLOW_PROMPT=1 in your environment to force interactive input.

Run Tests
- From repo root:
  - julia --project test/runtests.jl
  - julia --project test/test_validation.jl _ To validate the rows newly entered rows in the raw CSV file. 

CSV Expectations
- Required columns (case-insensitive names are normalized):
  - annual_income, loan_amount (or loan_dollar_amount), term, purpose, grade, dti (or debt_to_income_ratio)
- Optional columns used for reporting if present:
  - monthly_installment (from installment), int_rate, total_accounts (from total_acc)
- The loader normalizes: purpose → lowercase, grade → uppercase, computes debt_to_income_ratio if missing.

Notes
- Older exploratory scripts have been deprecated in favor of the new modules and tests.
