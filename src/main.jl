using CSV, DataFrames, Statistics
include("input_handling.jl")
include("calculations.jl")
include("reporting.jl")

function main()
    println("Enter path to CSV dataset (or press Enter for default '0. loan_data.csv'):")
    path = readline()
    file_path = isempty(path) ? joinpath(@__DIR__, "../0. loan_data.csv") : path

    data = CSV.read(file_path, DataFrame)

    # Get thresholds from dataset
    thresholds, grades = derive_thresholds(data)

    # Get applicant input
    (annual_income, loan_amount, monthly_term, purpose) = get_user_input()
    dti = compute_dti(annual_income, loan_amount, monthly_term)

    # Grade applicant
    grade = grade_loan(dti, thresholds, grades)
    avg_dti = compare_with_dataset(dti, data, purpose, monthly_term)

    # Print results
    println("------------------------------------------------")
    println("Applicant Debt-to-Income Ratio: ", round(dti, digits=3))
    if avg_dti !== missing
        println("Average DTI for similar loans: ", round(avg_dti, digits=3))
    else
        println("No matching loans found in dataset for comparison.")
    end
    println("Assigned Grade: ", grade)
    println(make_recommendation(grade))
    println("------------------------------------------------")
end

main()
