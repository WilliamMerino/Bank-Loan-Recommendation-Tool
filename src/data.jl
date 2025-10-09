using CSV
using DataFrames

function load_data(path::AbstractString)::DataFrame
    return CSV.read(path, DataFrame)
end

function normalize_columns(df::DataFrame)::DataFrame
    df = copy(df)
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

    if hasproperty(df, :purpose)
        df.purpose = lowercase.(coalesce.(df.purpose, ""))
    end
    if hasproperty(df, :grade)
        df.grade = uppercase.(coalesce.(df.grade, ""))
    end

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
    return df
end

