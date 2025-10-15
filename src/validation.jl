using CSV
using DataFrames
using Dates

const REQUIRED_COLUMNS = [
    :id, :address_state, :application_type, :emp_length, :grade,
    :home_ownership, :issue_date, :last_credit_pull_date,
    :last_payment_date, :loan_status, :member_id, :purpose,
    :sub_grade, :term, :verification_status, :annual_income,
    :debt_to_income_ratio, :monthly_installment, :int_rate,
    :loan_amount, :total_accounts, :total_payment
]

const ALLOWED_GRADES = Set(["A", "B", "C", "D", "E", "F", "G"])
const ALLOWED_TERMS = Set([36, 60])
const ALLOWED_HOME = Set(["RENT", "OWN", "MORTGAGE", "OTHER", "ANY", "NONE"])
const ALLOWED_VERIFICATION = Set(["Verified", "Source Verified", "Not Verified"])
const ALLOWED_APPLICATION_TYPES = Set(["INDIVIDUAL", "JOINT", "DIRECT_PAY"])

const DATE_FORMAT = DateFormat("m/d/y")

"""
    parse_term(term_value)

Extract the numeric term (in months) from dataset cells such as `" 60 months"`.
Returns `missing` if the term cannot be parsed.
"""
function parse_term(term_value)
    if ismissing(term_value)
        return missing
    elseif term_value isa Integer
        return term_value
    elseif term_value isa AbstractString
        m = match(r"\d+", term_value)
        return m === nothing ? missing : parse(Int, m.match)
    else
        return missing
    end
end

"""
    parse_emp_length(value)

Normalize employment length strings (e.g., `"10+ years"`, `"3 years"`, `"< 1 year"`)
to an integer number of years between 0 and 10, returning `missing` if parsing fails.
"""
function parse_emp_length(value)
    if ismissing(value)
        return missing
    end
    v = strip(String(value))
    if v == "< 1 year"
        return 0
    elseif occursin("10", v) && occursin("+", v)
        return 10
    elseif occursin(r"^\d+\s+year", lowercase(v))
        return tryparse(Int, first(split(v)))
    else
        return tryparse(Int, replace(v, r"[^0-9]" => ""))
    end
end

"""
    validate_row(row)::Vector{String}

Check a single normalized dataset row and return a list of human-readable
issues that were detected. An empty vector indicates a valid row.
"""
function validate_row(row)::Vector{String}
    issues = String[]

    for col in REQUIRED_COLUMNS
        if !(col in propertynames(row))
            push!(issues, "missing required column `$(col)`")
        elseif ismissing(getproperty(row, col))
            push!(issues, "`$(col)` must not be missing")
        end
    end

    has_grade = hasproperty(row, :grade) && !ismissing(row.grade)
    if has_grade
        grade = String(row.grade)
        if !(grade in ALLOWED_GRADES)
            push!(issues, "grade must be one of $(collect(ALLOWED_GRADES)), got $(grade)")
        end
    end

    if hasproperty(row, :sub_grade) && !ismissing(row.sub_grade)
        sub = String(row.sub_grade)
        if !occursin(r"^[A-G][1-5]$", sub)
            push!(issues, "sub_grade should match pattern A1–G5, got $(sub)")
        elseif has_grade && first(sub) != first(String(row.grade))
            push!(issues, "sub_grade $(sub) does not align with grade $(row.grade)")
        end
    end

    if hasproperty(row, :annual_income) && !ismissing(row.annual_income)
        income = Float64(row.annual_income)
        if income <= 0
            push!(issues, "annual_income must be > 0, got $(income)")
        elseif income > 1_000_000_000
            push!(issues, "annual_income is implausibly large ($(income))")
        end
    end

    if hasproperty(row, :loan_amount) && !ismissing(row.loan_amount)
        amount = Float64(row.loan_amount)
        if amount <= 0
            push!(issues, "loan_amount must be > 0, got $(amount)")
        end
    end

    if hasproperty(row, :monthly_installment) && !ismissing(row.monthly_installment)
        installment = Float64(row.monthly_installment)
        if installment <= 0
            push!(issues, "monthly_installment must be > 0, got $(installment)")
        end
    end

    if hasproperty(row, :debt_to_income_ratio) && !ismissing(row.debt_to_income_ratio)
        dti = Float64(row.debt_to_income_ratio)
        if dti < 0 || dti > 2
            push!(issues, "debt_to_income_ratio should be between 0 and 2, got $(dti)")
        end
    end

    if hasproperty(row, :int_rate) && !ismissing(row.int_rate)
        rate = Float64(row.int_rate)
        if rate < 0 || rate > 1
            push!(issues, "int_rate should be between 0 and 1, got $(rate)")
        end
    end

    if hasproperty(row, :total_accounts) && !ismissing(row.total_accounts)
        total_accts = Int(row.total_accounts)
        if total_accts < 0
            push!(issues, "total_accounts must be >= 0, got $(total_accts)")
        end
    end

    if hasproperty(row, :total_payment) && !ismissing(row.total_payment)
        total_pay = Float64(row.total_payment)
        if total_pay < 0
            push!(issues, "total_payment must be >= 0, got $(total_pay)")
        end
    end

    if hasproperty(row, :term) && !ismissing(row.term)
        term_months = parse_term(row.term)
        if term_months === missing
            push!(issues, "term value `$(row.term)` could not be parsed to months")
        elseif !(term_months in ALLOWED_TERMS)
            push!(issues, "term should be 36 or 60 months, got $(term_months)")
        end
    end

    if hasproperty(row, :home_ownership) && !ismissing(row.home_ownership)
        home = uppercase(String(row.home_ownership))
        if !(home in ALLOWED_HOME)
            push!(issues, "home_ownership $(row.home_ownership) not in allowed set $(collect(ALLOWED_HOME))")
        end
    end

    if hasproperty(row, :verification_status) && !ismissing(row.verification_status)
        status = String(row.verification_status)
        if !(status in ALLOWED_VERIFICATION)
            push!(issues, "verification_status $(status) not in $(collect(ALLOWED_VERIFICATION))")
        end
    end

    if hasproperty(row, :application_type) && !ismissing(row.application_type)
        app = String(row.application_type)
        if !(app in ALLOWED_APPLICATION_TYPES)
            push!(issues, "application_type $(app) not in $(collect(ALLOWED_APPLICATION_TYPES))")
        end
    end

    for col in (:issue_date, :last_credit_pull_date, :last_payment_date, :next_payment_date)
        if hasproperty(row, col) && !ismissing(getproperty(row, col))
            val = String(getproperty(row, col))
            try
                Dates.Date(val, DATE_FORMAT)
            catch
                push!(issues, "$(col)=$(val) is not a valid m/d/y date")
            end
        end
    end

    if hasproperty(row, :emp_length) && !ismissing(row.emp_length)
        emp = parse_emp_length(row.emp_length)
        if emp === nothing || emp === missing || emp < 0 || emp > 40
            push!(issues, "emp_length `$(row.emp_length)` could not be interpreted")
        end
    end

    return issues
end

"""
    validate_dataset(df::DataFrame) -> Vector{NamedTuple}

Return a vector of discrepancies found across the dataset. Each entry reports the
row number (1-based) and the associated issue list.
"""
function validate_dataset(df::DataFrame)
    discrepancies = NamedTuple[]
    for (idx, row) in enumerate(eachrow(df))
        row_issues = validate_row(row)
        if !isempty(row_issues)
            push!(discrepancies, (row=idx, issues=row_issues))
        end
    end
    return discrepancies
end

"""
    validate_dataset_file(path::AbstractString) -> Vector{NamedTuple}

Convenience wrapper that reads the CSV, normalizes columns, and returns any issues.
"""
function validate_dataset_file(path::AbstractString)
    df = CSV.read(path, DataFrame)
    df = normalize_columns(df)
    return validate_dataset(df)
end
