global HAS_XLSX = false
try
    import XLSX
    global HAS_XLSX = true
catch
    # XLSX not available
end

using DataFrames, Statistics, CSV

# --- Step 1: Load dataset (CSV or XLSX) ---
function load_data(file_path::String, sheet_name::String="")
    if endswith(lowercase(file_path), ".csv")
        data = CSV.read(file_path, DataFrame)
    else
        if !HAS_XLSX
            error("XLSX package not available. Install it with `import Pkg; Pkg.add(\"XLSX\")` or provide a CSV dataset.")
        end
        sheet = sheet_name == "" ? "Sheet1" : sheet_name
        data = DataFrame(XLSX.readtable(file_path, sheet)...)
    end

    # Clean `monthly_term` column: remove non-digits and parse Int (e.g. " 36 months" -> 36)
    if :monthly_term in names(data)
        try
            data.monthly_term = parse.(Int, replace.(strip.(string.(data.monthly_term)), r"[^0-9]" => ""))
        catch
            # leave as-is if parsing fails
        end
    end

    # Normalize `purpose` to lowercase trimmed strings
    if :purpose in names(data)
        data.purpose = lowercase.(strip.(string.(data.purpose)))
    end

    # If dataset already has a debt-to-income column, map it to `:dti`
    if :debt_to_income_ratio in names(data) && !(:dti in names(data))
        try
            data.dti = Float64.(data.debt_to_income_ratio)
        catch
            # if conversion fails, try parsing as strings
            try
                data.dti = parse.(Float64, replace.(string.(data.debt_to_income_ratio), r"[^0-9\.]" => ""))
            catch
                # leave absent if cannot convert
            end
        end
    end

    return data
end
# --- Step 2: Compute Monthly DTI ---
function compute_dti(annual_income, loan_amount, monthly_term)
    monthly_income = annual_income / 12
    monthly_payment = loan_amount / monthly_term
    return monthly_payment / monthly_income
end

# --- Step 4: Grade Loan ---
function grade_loan(dti::Float64; thresholds=(0.1, 0.2, 0.35))
    a, b, c = thresholds
    if dti <= a
        return "A"
    elseif dti <= b
        return "B"
    elseif dti <= c
        return "C"
    else
        return "D"
    end
end

# --- Step 5: Make Recommendation ---
function make_recommendation(grade::String)
    if grade in ["A", "B"]
        return "✅ Recommended: Low to medium risk loan."
    else
        return "❌ Not Recommended: High risk loan."
    end
end

# --- Step 6: Compare applicant with dataset ---
function compare_with_dataset(dti::Float64, data::DataFrame, purpose::String, monthly_term::Int)
    filtered = filter(row -> row.purpose == purpose && row.monthly_term == monthly_term, data)

    if nrow(filtered) == 0
        return missing
    else
        return mean(filtered.dti)
    end
end

# --- Main Program ---
function main()
<<<<<<< HEAD
    # Load dataset from CSV
    data = load_data("C:/Users/willi/Documents/MyProject/loan_data.csv")
=======
    # Attempt to locate a dataset file in the project folder
    candidates = ["Bank loan tool data - financial_loan.csv", "loan_data.xlsx", "loan_data.csv", "financial_loan.csv"]
    dataset = ""
    for f in candidates
        if isfile(f)
            dataset = f
            break
        end
    end
    if dataset == ""
        error("No dataset found. Place a CSV/XLSX dataset in the project folder and re-run.")
    end

    # Load dataset (sheet name optional)
    data = load_data(dataset)
>>>>>>> 024ccbc (Add CSV-compatible loader and cleaning to Project; add find_interest_rate.jl for per-grade interest stats)

    # Compute DTI column for dataset if missing
    if !(:dti in names(data))
        if (:loan_dollar_amount in names(data)) && (:monthly_term in names(data)) && (:annual_income in names(data))
            data.dti = (Float64.(data.loan_dollar_amount) ./ Float64.(data.monthly_term)) ./ (Float64.(data.annual_income) ./ 12.0)
        end
    end

    # Get applicant input (interactive)
    annual_income = 0.0
    loan_amount = 0.0
    monthly_term = 0
    purpose = ""
    try
        (annual_income, loan_amount, monthly_term, purpose) = get_user_input()
    catch err
        println("Interactive input not available. Running demo applicant for testing.")
        annual_income = 60000.0
        loan_amount = 12000.0
        monthly_term = 36
        purpose = "car"
    end
    dti = compute_dti(annual_income, loan_amount, monthly_term)

    # Grade and compare
    grade = grade_loan(dti; thresholds=(0.1, 0.2, 0.35))
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
