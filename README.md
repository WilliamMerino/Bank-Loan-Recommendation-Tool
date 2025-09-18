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
