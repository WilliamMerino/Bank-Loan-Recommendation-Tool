using DataFrames

function top_similar_by_dti(cohort::DataFrame, applicant_dti::Real; top_n::Int=5)
    diffs = abs.(coalesce.(cohort.debt_to_income_ratio, Inf) .- applicant_dti)
    sorted_indices = sortperm(diffs)
    n = min(top_n, length(sorted_indices))
    return cohort[sorted_indices[1:n], :]
end

function top_similar_by_vector(cohort::DataFrame, values::AbstractVector{<:Real}, applicant_value::Real; top_n::Int=5)
    diffs = abs.(values .- applicant_value)
    sorted_indices = sortperm(diffs)
    n = min(top_n, length(sorted_indices))
    return cohort[sorted_indices[1:n], :]
end
