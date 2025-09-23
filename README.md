# Bank-Loan-Recommendation-Tool

We are going to use past financial data for loans that have been applied for at a bank. We are able to see through all this past data trends of what would be seen as a risk to give certain people loans. We want to be able to create a bank loan recommendation tool.

Our Goal: We want to create a tool where a person can go online and see the "grade" or probability that they will get the loan if they were to apply for it

Step 1. Define the data elements we will use to analyze to help us reach the final outcome

The elements we will not use from the data include:
id - we do not need for our use case as we do not need to specifically identify certain people within the dataset
address_state - not relevant for our use case
application_type - they are all "INDIVIDUAL"
emp_title - not relevant for our use case
verification_status - of their income source is not relevant for our use case
issue_date - not relevant for our use case
last_credit_pull_date - not relevant for our use case
last_payment_date - not relevant for our use case
next_payment_date - not relevant for our use case
member_id - not relevant for our use case

next meeting we will figure out how to read the data and find the correlation between the elements

in the dataset we acquired, we were unable to find how the original team calculated the debt_to_income ratio - as a result, we have decided to recalculate the debt_to_income ratio using the formula: 

we have decided to clean the data further and reduce the number of home_ownership options avaialble to only include own, mortagage, or rent - the other options included none and other which we decided to get rid of
we have also decided to clean the data related to the purpose of the loan to only include - car, house, and educational
the ones we have decided to delete include - credit card, debt consolidation, home improvement, major purchase, medical, moving, other, renewable energy, small business, vacation, and wedding
the data is now reflecting those that either rent, own, or have a mortgage which have all applied for loans for car, house, and educational
<<<<<<< HEAD
## Run

To run the analysis with the project environment:

```bash
cd ~/Desktop/BANK_RECOMMENDATION_TOOL/Bank-Loan-Recommendation-Tool
# install recorded dependencies and precompile
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# run the analysis script
julia --project=. analysis.jl
```

If you want a reproducible environment to be tracked in git, remove `Manifest.toml` from `.gitignore` and commit the `Manifest.toml` file.
=======

to install the notebook:
open Julia in your terminal then -

using Pkg
Pkg.add("Pluto")

git clone https://github.com/WilliamMerino/Bank-Loan-Recommendation-Tool.git

using Pluto
Pluto.run()

<img width="1000" height="800" alt="generated_image" src="https://github.com/user-attachments/assets/448976b6-8a80-4865-8aa3-72c2c438b6ab" />
>>>>>>> origin/main
