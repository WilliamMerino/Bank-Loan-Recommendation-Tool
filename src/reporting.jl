function make_recommendation(grade::String)
    if grade in ["A", "B"]
        return "✅ Recommended: Low to medium risk loan."
    else
        return "❌ Not Recommended: High risk loan."
    end
end

function compare_with_dataset(dti::Float64, data::DataFrame, purpose::String, monthly_term::Int)
    filtered = filter(row -> row.purpose == purpose && row.monthly_term == monthly_term, data)
    return nrow(filtered) == 0 ? missing : mean(filtered.debt_to_income_ratio)
end
