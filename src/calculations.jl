using DataFrames, Statistics

function compute_dti(annual_income, loan_amount, monthly_term)
    monthly_income = annual_income / 12
    monthly_payment = loan_amount / monthly_term
    return monthly_payment / monthly_income
end

function derive_thresholds(data::DataFrame)
    if !("grade" in names(data))
        error("Dataset must contain a 'grade' column.")
    end
    grades = unique(data.grade)
    dtis = [mean(filter(row -> row.grade == g, data).debt_to_income_ratio) for g in grades]
    return dtis, grades
end

function grade_loan(dti::Float64, thresholds::Vector{Float64}, grades::Vector{String})
    idx = findfirst(x -> dti <= x, thresholds)
    return idx === nothing ? last(grades) : grades[idx]
end
