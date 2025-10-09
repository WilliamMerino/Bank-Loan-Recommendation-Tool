using DataFrames
using Statistics

function compute_applicant_dti(annual_income::Real, loan_amount::Real, monthly_term::Real)
    monthly_payment = loan_amount / monthly_term
    monthly_income = annual_income / 12
    return monthly_payment / monthly_income
end

safe_mean(values) = begin
    non_missing = collect(skipmissing(values))
    isempty(non_missing) ? NaN : mean(non_missing)
end

function derive_purpose_thresholds(cohort::DataFrame)
    # Default to risk-score based thresholds if enough columns are present; otherwise fallback to DTI
    required_cols = [:annual_income, :loan_amount, :term]
    has_required = all(c -> c in names(cohort), required_cols)
    has_grade = :grade in names(cohort)
    if has_required && has_grade
        th = derive_purpose_thresholds_risk(cohort)
        return (thresholds=th.thresholds, labels=th.labels, grades=th.grades, mode=:risk)
    else
        th = derive_purpose_thresholds_dti(cohort)
        return (thresholds=th.thresholds, labels=th.labels, grades=th.grades, mode=:dti)
    end
end

function assign_grade(applicant_dti::Real, thresholds::Vector{Float64}, grade_order::Vector{String})
    assigned = grade_order[end]
    for (i, t) in enumerate(thresholds)
        if applicant_dti <= t
            assigned = grade_order[i]
            break
        end
    end
    return assigned
end

# ----------------------
# Risk-score refinement
# ----------------------

"""
    normalize_emp_length!(df)

Convert common `emp_length` strings to numeric years 0–10.
"""
function normalize_emp_length!(df::DataFrame)
    if :emp_length in names(df)
        mapping = Dict(
            "< 1 year" => "0", "1 year" => "1", "2 years" => "2", "3 years" => "3",
            "4 years" => "4", "5 years" => "5", "6 years" => "6", "7 years" => "7",
            "8 years" => "8", "9 years" => "9", "10+ years" => "10"
        )
        df.emp_length = replace.(coalesce.(df.emp_length, "0"), mapping)
        df.emp_length = parse.(Float64, df.emp_length)
    end
    return df
end

"""
    normalize_term!(df)

Ensure `term` is an Int (e.g., strip " months" if present).
"""
function normalize_term!(df::DataFrame)
    if :term in names(df)
        if eltype(df.term) <: AbstractString
            df.term = parse.(Int, replace.(df.term, r"\s*months" => ""))
        end
    end
    return df
end

function compute_risk_score(row; weights=Dict(
    :dti => 0.35,
    :lti => 0.25,
    :emp_length => -0.10,
    :total_accounts => -0.10,
    :term => 0.10,
    :home_rent => 0.10,
    :verified => -0.10,
    :purpose_wedding => 0.05,
))
    annual_income = getproperty(row, :annual_income)
    loan_amount = getproperty(row, :loan_amount)
    term = getproperty(row, :term)
    dti = hasproperty(row, :debt_to_income_ratio) ? getproperty(row, :debt_to_income_ratio) : compute_applicant_dti(annual_income, loan_amount, term)
    lti = loan_amount / annual_income
    emp = hasproperty(row, :emp_length) ? getproperty(row, :emp_length) : 0
    total_accts = hasproperty(row, :total_accounts) ? getproperty(row, :total_accounts) : 0
    home = hasproperty(row, :home_ownership) ? getproperty(row, :home_ownership) : ""
    ver = hasproperty(row, :verification_status) ? getproperty(row, :verification_status) : ""
    purp = hasproperty(row, :purpose) ? getproperty(row, :purpose) : ""

    term_norm = term / 36
    home_rent = isequal(uppercase(string(home)), "RENT") ? 1 : 0
    # Verification score: Not Verified=0, Verified=0.75, Source Verified=1.0
    ver_str = lowercase(string(ver))
    verified = if occursin("source verified", ver_str)
        1.0
    elseif occursin("verified", ver_str)
        0.75
    else
        0.0
    end
    purpose_wedding = isequal(lowercase(string(purp)), "wedding") ? 1 : 0

    # Normalize total accounts to a 0..1 scale (cap at 20+ accounts)
    total_accts_norm = clamp((total_accts isa Number ? total_accts : 0) / 20, 0, 1)

    score = weights[:dti] * dti +
            weights[:lti] * lti +
            weights[:emp_length] * (emp isa Number ? emp/10 : 0.0) +
            weights[:total_accounts] * total_accts_norm +
            weights[:term] * (term_norm - 1) +
            weights[:home_rent] * home_rent +
            weights[:verified] * verified +
            weights[:purpose_wedding] * purpose_wedding
    return score
end

function derive_purpose_thresholds_risk(cohort::DataFrame; percentile=0.5)
    normalize_emp_length!(cohort)
    normalize_term!(cohort)

    cohort[!, :risk_score] = [compute_risk_score(row) for row in eachrow(cohort)]

    grade_order = ["A","B","C","D","E","F","G"]
    medians = Dict{String, Float64}()
    prev_med = 0.0
    for g in grade_order
        scores = coalesce.(cohort[coalesce.(cohort.grade, "") .== g, :risk_score], missing)
        nonmiss = collect(skipmissing(scores))
        if !isempty(nonmiss)
            med = quantile(nonmiss, percentile)
            if isnan(med)
                med = maximum(nonmiss)
            end
            if med <= prev_med
                med = nextfloat(prev_med)
            end
            medians[g] = med
            prev_med = med
        else
            med = nextfloat(prev_med)
            medians[g] = med
            prev_med = med
        end
    end

    thresholds = Float64[]
    labels = String[]
    for i in 1:(length(grade_order)-1)
        g1, g2 = grade_order[i], grade_order[i+1]
        med1 = get(medians, g1, Inf)
        med2 = get(medians, g2, Inf)
        threshold = if isinf(med1) || isinf(med2)
            Inf
        elseif med1 == med2
            scores1 = coalesce.(cohort[coalesce.(cohort.grade, "") .== g1, :risk_score], missing)
            nonmiss1 = collect(skipmissing(scores1))
            isempty(nonmiss1) ? med1 : maximum(nonmiss1)
        else
            (med1 + med2) / 2
        end
        push!(thresholds, threshold)
        push!(labels, g1)
    end
    push!(labels, grade_order[end])

    for i in 2:length(thresholds)
        if thresholds[i] <= thresholds[i-1]
            thresholds[i] = nextfloat(thresholds[i-1])
        end
    end

    # Optional: simple re-assignment accuracy metric
    if :risk_score in names(cohort) && :grade in names(cohort)
        valid = .!ismissing.(cohort.risk_score) .& .!ismissing.(cohort.grade)
        if any(valid)
            reassigned = [assign_grade(s, thresholds, grade_order) for s in cohort.risk_score[valid]]
            acc = mean(reassigned .== cohort.grade[valid]) * 100
            @info "Risk score re-assignment accuracy" accuracy=round(acc, digits=1)
        end
    end

    return (thresholds=thresholds, labels=labels, grades=grade_order)
end

function derive_purpose_thresholds_dti(cohort::DataFrame)
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
            if med <= prev_med
                med = nextfloat(prev_med)
            end
            medians[g] = med
            prev_med = med
        else
            med = nextfloat(prev_med)
            medians[g] = med
            prev_med = med
        end
    end

    thresholds = Float64[]
    labels = String[]
    for i in 1:(length(grade_order)-1)
        g1 = grade_order[i]
        g2 = grade_order[i+1]
        med1 = get(medians, g1, Inf)
        med2 = get(medians, g2, Inf)
        threshold = if isinf(med1) || isinf(med2)
            Inf
        elseif med1 == med2
            dtis1 = coalesce.(cohort[coalesce.(cohort.grade, "") .== g1, :debt_to_income_ratio], missing)
            nonmiss1 = collect(skipmissing(dtis1))
            isempty(nonmiss1) ? med1 : maximum(nonmiss1)
        else
            (med1 + med2) / 2
        end
        push!(thresholds, threshold)
        push!(labels, g1)
    end
    push!(labels, grade_order[end])

    for i in 2:length(thresholds)
        if thresholds[i] <= thresholds[i-1]
            thresholds[i] = nextfloat(thresholds[i-1])
        end
    end

    return (thresholds=thresholds, labels=labels, grades=grade_order)
end
