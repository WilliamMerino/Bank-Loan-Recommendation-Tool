using Statistics

function make_recommendation(grade::String)
    if grade in ["A", "B"]
        return "Recommended: Low to medium risk loan."
    elseif grade in ["C", "D"]
        return "Medium risk: consider adjusting amount or debts."
    else
        return "High risk: approval may require higher interest or denial."
    end
end

function compare_with_dataset(dti::Float64, data, purpose::String, term_col::Symbol)
    # This function is retained for backward compatibility if needed
    filtered = filter(row -> getproperty(row, :purpose) == purpose && getproperty(row, term_col) == getproperty(row, term_col), data)
    return nrow(filtered) == 0 ? missing : mean(filtered.debt_to_income_ratio)
end
