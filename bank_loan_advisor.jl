using CSV
using DataFrames
using Statistics

function format_number_with_commas(n::Real; digits=2)::String
    if isnan(n) || isinf(n)
        return "N/A"
    end
    rounded = round(n; digits=digits)
    s = string(rounded)
    if occursin('.', s)
        parts = split(s, '.', limit=2)
        int_part = parts[1]
        dec_part = '.' * rpad(parts[2], digits, '0')
    else
        int_part = s
        dec_part = '.' * repeat('0', digits)
    end
    # Add commas every 3 digits from the right in integer part
    int_part = replace(int_part, r"(\d)(?=(\d{3})+(?!\d))" => s"\1,")
    return int_part * dec_part
end

function format_currency(val::Real; digits=2)::String
    if isnan(val) || isinf(val)
        return "N/A"
    end
    return "\$" * format_number_with_commas(val; digits=digits)
end

function safe_mean(values)
    non_missing = collect(skipmissing(values))
    return isempty(non_missing) ? NaN : mean(non_missing)
end

function compute_column_widths(headers::Vector{String}, rows::Vector{Vector{String}})
    widths = [length(h) for h in headers]
    for row in rows
        @assert length(row) == length(headers)
        for (i, cell) in enumerate(row)
            widths[i] = max(widths[i], length(cell))
        end
    end
    return widths
end

function make_separator(char::Char, widths::Vector{Int})
    segments = [repeat(string(char), w + 2) for w in widths]
    return "+" * join(segments, "+") * "+"
end

function format_table_row(row::Vector{String}, widths::Vector{Int}, alignments::Vector{Symbol})
    cells = Vector{String}(undef, length(row))
    for i in eachindex(row)
        cell = row[i]
        width = widths[i]
        alignment = alignments[i]
        padded = alignment === :right ? lpad(cell, width) : rpad(cell, width)
        cells[i] = " " * padded * " "
    end
    return "|" * join(cells, "|") * "|"
end

function print_table(headers::Vector{String}, rows::Vector{Vector{String}}; alignments::Union{Nothing, Vector{Symbol}}=nothing)
    if alignments === nothing
        alignments = fill(:left, length(headers))
    end
    header_alignments = fill(:left, length(headers))
    widths = compute_column_widths(headers, rows)
    top_border = make_separator('-', widths)
    header_border = make_separator('=', widths)
    println(top_border)
    println(format_table_row(headers, widths, header_alignments))
    println(header_border)
    for row in rows
        println(format_table_row(row, widths, alignments))
    end
    println(top_border)
end

function main()
    # Introduction
    println("=== Loan Grading Tool ===")
    println("Welcome! This interactive tool helps assess loan applications by calculating the Debt-to-Income (DTI) ratio and assigning a risk grade (A-G) based on a dataset of historical loans.")
    println("It provides personalized recommendations, compares your application to similar loans, and offers insights to improve affordability.")
    println("")
    println("How to use:")
    println("1. Provide the path to the CSV file containing the loan data.")
    println("2. Enter your applicant details: annual income, loan amount, term (36 or 60 months), purpose (car, educational, house), and number of existing debts.")
    println("3. Review the grade, recommendation, similar loans, and summary.")
    println("4. Process another loan or exit anytime.")
    println("Note: The tool derives purpose-specific thresholds from the data for accurate grading.")
    println("")

    default_path = joinpath(@__DIR__, "loan_data.csv")
    println("Enter the path to the CSV file (press Enter for default 'loan_data.csv'): ")
    path = strip(readline())
    file_path = isempty(path) ? default_path : path
    df = CSV.read(file_path, DataFrame)

    # Normalize column names
    if hasproperty(df, :loan_dollar_amount)
        rename!(df, :loan_dollar_amount => :loan_amount)
    end
    if hasproperty(df, :total_acc)
        rename!(df, :total_acc => :total_accounts)
    end
    if hasproperty(df, :dti)
        rename!(df, :dti => :debt_to_income_ratio)
    end
    if hasproperty(df, :installment)
        rename!(df, :installment => :monthly_installment)
    end
    if hasproperty(df, :term)
        # term is already :term
    end

    # Normalize purpose to lowercase
    if hasproperty(df, :purpose)
        df.purpose = lowercase.(coalesce.(df.purpose, ""))
    end

    # Normalize grade to uppercase
    if hasproperty(df, :grade)
        df.grade = uppercase.(coalesce.(df.grade, ""))
    end

    # Compute debt_to_income_ratio if missing
    if !hasproperty(df, :debt_to_income_ratio)
        df[!, :debt_to_income_ratio] = Vector{Union{Float64, Missing}}(missing, nrow(df))
        for (i, row) in enumerate(eachrow(df))
            if !ismissing(row.annual_income) && !ismissing(row.loan_amount) && !ismissing(row.term) &&
               row.annual_income > 0 && row.term > 0
                monthly_payment = row.loan_amount / row.term
                monthly_income = row.annual_income / 12
                df[i, :debt_to_income_ratio] = monthly_payment / monthly_income
            end
        end
    end

    while true
        # User inputs with validation
        annual_income = get_positive_float("Enter annual income (e.g., 60000): ")
        loan_amount = get_positive_float("Enter loan amount (e.g., 10000): ")
        monthly_term = get_valid_term("Enter monthly term (36 or 60): ")
        purpose = get_valid_purpose("Enter purpose (car, educational, house): ")
        num_debts = get_non_negative_int("Enter number of existing debts: ")

        # Compute applicant DTI
        monthly_payment = loan_amount / monthly_term
        monthly_income = annual_income / 12
        applicant_dti = monthly_payment / monthly_income

        # Filter cohort by purpose
        cohort = filter(row -> !ismissing(row.purpose) && row.purpose == purpose, df)

        if nrow(cohort) == 0
            println("\nNo data available for purpose '$purpose'. Skipping this loan.")
            println("\nProcess another loan? (y/n): ")
            if lowercase(strip(readline())) != "y"
                break
            end
            continue
        end

        # Derive thresholds, always assuming A-G
        grade_order = ["A", "B", "C", "D", "E", "F", "G"]
        medians = Dict{String, Float64}()
        prev_med = 0.0
        for g in grade_order
            dtis = coalesce.(cohort[coalesce.(cohort.grade, "") .== g, :debt_to_income_ratio], missing)
            nonmiss = collect(skipmissing(dtis))
            if !isempty(nonmiss)
                med = median(nonmiss)
                if isnan(med)
                    med = maximum(nonmiss)
                end
                # Ensure increasing
                if med <= prev_med
                    med = nextfloat(prev_med)
                end
                medians[g] = med
                prev_med = med
            else
                # Fallback for missing grades: interpolate or extend from previous
                med = nextfloat(prev_med)
                medians[g] = med
                prev_med = med
            end
        end

        thresholds = Float64[]
        threshold_labels = String[]
        for i in 1:(length(grade_order)-1)
            g1 = grade_order[i]
            g2 = grade_order[i+1]
            med1 = get(medians, g1, Inf)
            med2 = get(medians, g2, Inf)
            if isinf(med1) || isinf(med2)
                threshold = Inf
            elseif med1 == med2
                dtis1 = coalesce.(cohort[coalesce.(cohort.grade, "") .== g1, :debt_to_income_ratio], missing)
                nonmiss1 = collect(skipmissing(dtis1))
                threshold = isempty(nonmiss1) ? med1 : maximum(nonmiss1)
            else
                threshold = (med1 + med2) / 2
            end
            push!(thresholds, threshold)
            push!(threshold_labels, g1)
        end
        if !isempty(grade_order)
            push!(threshold_labels, grade_order[end])
        end

        # Enforce strictly ascending thresholds
        for i in 2:length(thresholds)
            if thresholds[i] <= thresholds[i-1]
                thresholds[i] = nextfloat(thresholds[i-1])
            end
        end

        # Assign grade
        assigned_grade = grade_order[end]
        for (i, t) in enumerate(thresholds)
            if applicant_dti <= t
                assigned_grade = grade_order[i]
                break
            end
        end

        # More descriptive recommendation
        formatted_income = format_currency(annual_income)
        formatted_loan = format_currency(loan_amount)
        recommendation = if assigned_grade in ["A", "B"]
            "Low to medium risk: Your DTI of $applicant_dti indicates strong affordability for this $purpose loan of $formatted_loan over $monthly_term months, given your annual income of $formatted_income and $num_debts existing debts. We recommend approval with favorable terms."
        elseif assigned_grade in ["C", "D"]
            "Medium risk: Your DTI of $applicant_dti suggests moderate affordability for this $purpose loan. Consider reviewing your $num_debts existing debts or adjusting the loan amount of $formatted_loan to improve your grade."
        else
            "High risk: Your DTI of $applicant_dti is elevated for this $purpose loan, potentially straining your annual income of $formatted_income with $num_debts existing debts. Approval may require higher interest or denial; explore smaller loans or user needs to increase income."
        end

        # Cohort averages
        avg_dti = safe_mean(cohort.debt_to_income_ratio)
        avg_monthly_installment = hasproperty(cohort, :monthly_installment) ? safe_mean(cohort.monthly_installment) : NaN
        avg_int_rate = hasproperty(cohort, :int_rate) ? safe_mean(cohort.int_rate) : NaN
        avg_total_accounts = hasproperty(cohort, :total_accounts) ? safe_mean(cohort.total_accounts) : NaN

        # Similarity
        diffs = abs.(coalesce.(cohort.debt_to_income_ratio, Inf) .- applicant_dti)
        sorted_indices = sortperm(diffs)
        top_n = min(5, length(sorted_indices))
        similar_loans = cohort[sorted_indices[1:top_n], :]

        # Output
        println("\nDerived thresholds (A-G):")
        for (i, label) in enumerate(threshold_labels[1:end-1])
            println("$label: $(thresholds[i])")
        end

        println("\nApplicant DTI: $applicant_dti")
        println("Average cohort DTI: $avg_dti")

        println("\nAssigned grade: $assigned_grade")
        println("Recommendation: $recommendation")

        println("\nTop 5 similar loans (sorted by closest DTI):")
        headers = ["Loan #", "Amount", "Term", "Income", "DTI", "Grade", "Installment", "Int Rate (%)", "Total Accts"]
        table_rows = Vector{Vector{String}}()
        for (i, row) in enumerate(eachrow(similar_loans))
            dti_str = ismissing(row.debt_to_income_ratio) ? "missing" : string(round(row.debt_to_income_ratio; digits=4))
            amount_str = ismissing(row.loan_amount) ? "missing" : format_currency(row.loan_amount)
            income_str = ismissing(row.annual_income) ? "missing" : format_currency(row.annual_income)
            if hasproperty(similar_loans, :monthly_installment)
                inst_str = ismissing(row.monthly_installment) ? "missing" : format_currency(row.monthly_installment)
            else
                inst_str = "N/A"
            end
            if hasproperty(similar_loans, :int_rate)
                rate_str = ismissing(row.int_rate) ? "missing" : "$(round(row.int_rate * 100; digits=2))%"
            else
                rate_str = "N/A"
            end
            if hasproperty(similar_loans, :total_accounts)
                accts_str = ismissing(row.total_accounts) ? "missing" : string(row.total_accounts)
            else
                accts_str = "N/A"
            end
            push!(table_rows, [string(i), amount_str, ismissing(row.term) ? "missing" : string(row.term), income_str, dti_str, ismissing(row.grade) ? "missing" : string(row.grade), inst_str, rate_str, accts_str])
        end
        alignments = [:right, :right, :right, :right, :right, :left, :right, :right, :right]
        print_table(headers, table_rows; alignments=alignments)

        # Enhanced summary paragraph
        formatted_avg_installment = isnan(avg_monthly_installment) ? "N/A" : format_currency(avg_monthly_installment)
        formatted_avg_rate = isnan(avg_int_rate) ? "N/A" : "$(round(avg_int_rate * 100; digits=2))%"
        println("\nSummary:")
        println("For your proposed $purpose loan: With an annual income of $formatted_income, requesting $formatted_loan over $monthly_term months, and having $num_debts existing debts, we've calculated your Debt-to-Income (DTI) ratio as $applicant_dti. Compared to the average DTI of $avg_dti for similar loans in the dataset, this results in a grade of $assigned_grade. $recommendation Additionally, cohort averages include: Monthly Installment $formatted_avg_installment, Interest Rate $formatted_avg_rate, Total Accounts $(isnan(avg_total_accounts) ? "N/A" : avg_total_accounts). Review the top similar loans above for more context on comparable applicants.")

        println("\nProcess another loan? (y/n): ")
        if lowercase(strip(readline())) != "y"
            break
        end
    end
end

function get_positive_float(prompt)
    while true
        println(prompt)
        input = strip(readline())
        try
            val = parse(Float64, input)
            if val > 0
                return val
            else
                println("Value must be positive.")
            end
        catch
            println("Invalid input. Enter a positive number.")
        end
    end
end

function get_valid_term(prompt)
    while true
        println(prompt)
        input = strip(readline())
        try
            val = parse(Int, input)
            if val in [36, 60]
                return val
            else
                println("Value must be 36 or 60.")
            end
        catch
            println("Invalid input. Enter 36 or 60.")
        end
    end
end

function get_valid_purpose(prompt)
    allowed = ["car", "educational", "house"]
    while true
        println(prompt)
        input = lowercase(strip(readline()))
        if input in allowed
            return input
        else
            println("Invalid purpose. Must be one of: car, educational, house.")
        end
    end
end

function get_non_negative_int(prompt)
    while true
        println(prompt)
        input = strip(readline())
        try
            val = parse(Int, input)
            if val >= 0
                return val
            else
                println("Value must be non-negative.")
            end
        catch
            println("Invalid input. Enter a non-negative integer.")
        end
    end
end

main()
