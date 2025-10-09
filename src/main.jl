# Bootstrap dependencies: ensure CSV/DataFrames are available
try
    @eval using CSV, DataFrames
catch err
    @warn "Dependencies missing; activating project and instantiating..." err
    import Pkg
    Pkg.activate(dirname(@__DIR__))
    try
        Pkg.instantiate()
        @eval using CSV, DataFrames
    catch
        # Fallback: explicitly add core deps if instantiate is insufficient
        Pkg.add(["CSV","DataFrames"]) 
        Pkg.precompile()
        @eval using CSV, DataFrames
    end
end

if !isdefined(Main, :BankLoanRecommendationTool)
    include("BankLoanRecommendationTool.jl")
end
using .BankLoanRecommendationTool
include("input_handling.jl")

function main()
    println("=== Loan Grading Tool ===")
    println("Welcome! This interactive tool helps assess loan applications by calculating the Debt-to-Income (DTI) ratio and assigning a risk grade (A–G) based on a dataset of historical loans.")
    println("It provides personalized recommendations, compares your application to similar loans, and offers insights to improve affordability.")
    println("")
    println("How to use:")
    println("1. We will assume the data is saved under loan_data.csv and use the data from that dataset as a default. If you would like to update or edit the data, please do so an and save it as loan_data.csv in the data folder.")
    println("2. Enter your applicant details: annual income, loan amount, term (36 or 60 months), purpose (car, educational, home improvement), employment length (0–10), home ownership (own/mortgage/rent), verification status, and total accounts.")
    println("3. Review the grade, recommendation, similar loans, and summary.")
    println("4. Process multiple loans or exit anytime.")
    println("Note: The tool derives purpose-specific thresholds from your data for accurate grading.")
    println("")

    # Always use the bundled dataset path; users only provide their inputs.
    default_path = joinpath(@__DIR__, "../data/loan_data.csv")
    file_path = default_path
    # Validate existence; fallback to default if needed
    if !isfile(file_path)
        println("Provided path not found: ", file_path)
        if isfile(default_path)
            println("Using default dataset instead: ", default_path)
            file_path = default_path
        else
            println("Default dataset not found at: ", default_path)
            println("Please provide a valid CSV path and retry.")
            return
        end
    end
    println("Using dataset at: ", file_path)
    df = load_data(file_path) |> normalize_columns
    println("Loaded rows: ", nrow(df))
    println("Proceeding to applicant inputs...\n")

    while true
        (annual_income, loan_amount, monthly_term, purpose, emp_length_years, home_ownership, verification_status, total_accounts) = get_user_input()

        applicant_dti = compute_applicant_dti(annual_income, loan_amount, monthly_term)
        cohort = filter(row -> !ismissing(row.purpose) && row.purpose == purpose, df)
        if nrow(cohort) == 0
            println("No data available for purpose '" * purpose * "'.")
        else
            # For user messaging, map canonical 'house' back to a friendlier label
            purpose_display = purpose == "house" ? "house improvement" : purpose
            th = derive_purpose_thresholds(cohort)
            # For applicant, compute risk score using provided inputs
            applicant_row = (
                annual_income=annual_income,
                loan_amount=loan_amount,
                term=monthly_term,
                purpose=purpose,
                debt_to_income_ratio=applicant_dti,
                emp_length=emp_length_years,
                home_ownership=home_ownership,
                verification_status=verification_status,
                total_accounts=total_accounts,
            )
            applicant_risk = BankLoanRecommendationTool.compute_risk_score(applicant_row)
            # Choose comparison metric based on threshold mode
            metric_used = th.mode == :risk ? applicant_risk : applicant_dti
            assigned_grade = assign_grade(metric_used, th.thresholds, th.grades)

            # Detailed thresholds (A–G)
            println("\nDerived thresholds (A–G):")
            if !isempty(th.thresholds)
                for (i, label) in enumerate(th.labels[1:end-1])
                    println(string(label, ": ", th.thresholds[i]))
                end
                # The highest grade (G) has no upper threshold; show its range explicitly
                last_label = th.labels[end]
                last_thr = th.thresholds[end]
                println(string(last_label, ": > ", last_thr))
            end

            # Cohort averages
            avg_dti = safe_mean(cohort.debt_to_income_ratio)
            avg_monthly_installment = hasproperty(cohort, :monthly_installment) ? safe_mean(cohort.monthly_installment) : NaN
            avg_int_rate = hasproperty(cohort, :int_rate) ? safe_mean(cohort.int_rate) : NaN
            avg_total_accounts = hasproperty(cohort, :total_accounts) ? safe_mean(cohort.total_accounts) : NaN

            # Recommendation
            println("\nApplicant DTI: ", round(applicant_dti, digits=4))
            println("Applicant Risk Score: ", round(applicant_risk, digits=4))
            println("Grading basis: ", th.mode == :risk ? "risk score vs thresholds" : "DTI vs thresholds")
            # Show nearest threshold context
            if !isempty(th.thresholds)
                metric_val = th.mode == :risk ? applicant_risk : applicant_dti
                idx = findfirst(x -> metric_val <= x, th.thresholds)
                if idx === nothing
                    println("Position: above highest threshold (grade G)")
                else
                    lower = idx == 1 ? nothing : th.thresholds[idx-1]
                    upper = th.thresholds[idx]
                    println("Position: between ", lower === nothing ? "-∞" : string(lower), " and ", string(upper))
                end
            end
            println("Average cohort DTI: ", avg_dti)
            println("\nAssigned grade: ", assigned_grade)
            println("Recommendation: ", make_recommendation(assigned_grade))

            # Similar loans table (align with grading basis)
            similar = if th.mode == :risk && (:risk_score in names(cohort))
                top_similar_by_vector(cohort, coalesce!(copy(cohort.risk_score), Inf), applicant_risk; top_n=5)
            else
                top_similar_by_dti(cohort, applicant_dti; top_n=5)
            end
            println("\nTop 5 similar loans (closest by $(th.mode == :risk ? "risk score" : "DTI")):")

            # Order columns to mirror user input sequence:
            # Income → Amount → Term → Purpose → Emp Yrs → Home → Verified → Total Accts
            # then computed/derived context: DTI → Grade → Installment → Int Rate
            headers = [
                "Loan #", "Income", "Amount", "Term", "Purpose",
                "Emp Yrs", "Home", "Verified", "Total Accts",
                "DTI", "Grade", "Installment", "Int Rate (%)"
            ]
            table_rows = Vector{Vector{String}}()
            for (i, row) in enumerate(eachrow(similar))
                dti_str = hasproperty(row, :debt_to_income_ratio) && !ismissing(row.debt_to_income_ratio) ? string(round(row.debt_to_income_ratio; digits=4)) : "N/A"
                amount_str = hasproperty(row, :loan_amount) && !ismissing(row.loan_amount) ? format_currency(row.loan_amount) : "N/A"
                income_str = hasproperty(row, :annual_income) && !ismissing(row.annual_income) ? format_currency(row.annual_income) : "N/A"
                term_str = hasproperty(row, :term) && !ismissing(row.term) ? string(row.term) : "N/A"
                grade_str = hasproperty(row, :grade) && !ismissing(row.grade) ? string(row.grade) : "N/A"
                emp_str = hasproperty(row, :emp_length) && !ismissing(row.emp_length) ? string(row.emp_length) : "N/A"
                home_str = hasproperty(row, :home_ownership) && !ismissing(row.home_ownership) ? string(row.home_ownership) : "N/A"
                ver_str = if hasproperty(row, :verification_status) && !ismissing(row.verification_status)
                    v = lowercase(string(row.verification_status))
                    occursin("source verified", v) ? "Source Verified" : (occursin("verified", v) ? "Verified" : "Not Verified")
                else
                    "N/A"
                end
                accts_str = hasproperty(row, :total_accounts) && !ismissing(row.total_accounts) ? string(row.total_accounts) : "N/A"
                inst_str = hasproperty(row, :monthly_installment) && !ismissing(row.monthly_installment) ? format_currency(row.monthly_installment) : "N/A"
                rate_str = hasproperty(row, :int_rate) && !ismissing(row.int_rate) ? string(round(row.int_rate * 100; digits=2), "%") : "N/A"
                purpose_str = hasproperty(row, :purpose) && !ismissing(row.purpose) ? string(row.purpose) : "N/A"

                push!(table_rows, [
                    string(i), income_str, amount_str, term_str, purpose_str,
                    emp_str, home_str, ver_str, accts_str,
                    dti_str, grade_str, inst_str, rate_str
                ])
            end

            aligns = [
                :right,  # Loan #
                :right,  # Income
                :right,  # Amount
                :right,  # Term
                :left,   # Purpose
                :right,  # Emp Yrs
                :left,   # Home
                :left,   # Verified
                :right,  # Total Accts
                :right,  # DTI
                :left,   # Grade
                :right,  # Installment
                :right   # Int Rate (%)
            ]
            print_table(headers, table_rows; alignments=aligns)

            # Enhanced summary paragraph
            formatted_income = format_currency(annual_income)
            formatted_loan = format_currency(loan_amount)
            formatted_avg_installment = isnan(avg_monthly_installment) ? "N/A" : format_currency(avg_monthly_installment)
            formatted_avg_rate = isnan(avg_int_rate) ? "N/A" : string(round(avg_int_rate * 100; digits=2), "%")
            println("\nSummary:")
            println(
                "For your proposed $(purpose_display) loan: With an annual income of $(formatted_income), requesting $(formatted_loan) over $(monthly_term) months, employment length $(emp_length_years) years, home ownership $(lowercase(home_ownership)), verification status $(verification_status), and total accounts $(total_accounts), we've calculated your Debt-to-Income (DTI) ratio as $(round(applicant_dti, digits=4)). " *
                "Compared to the average DTI of $(avg_dti) for similar loans in our dataset, this results in a grade of $(assigned_grade). " *
                "Additionally, cohort averages include: Monthly Installment $(formatted_avg_installment), Interest Rate $(formatted_avg_rate), Total Accounts " * (isnan(avg_total_accounts) ? "N/A" : string(avg_total_accounts)) * ". " *
                "Review the top similar loans above for more context on comparable applicants."
            )
        end

        println("\nProcess another loan? (y/n): ")
        if lowercase(strip(readline())) != "y"
            break
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
