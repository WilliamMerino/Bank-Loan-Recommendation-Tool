function get_user_input()
    annual_income = -1.0
    while annual_income <= 0
        println("Enter annual income (positive number, e.g., 40000):")
        try
            annual_income = parse(Float64, readline())
            if annual_income <= 0
                println("❌ Must be greater than 0.")
            end
        catch
            println("❌ Please enter a valid number.")
        end
    end

    loan_amount = -1.0
    while loan_amount <= 0
        println("Enter loan dollar amount (positive number, e.g., 12000):")
        try
            loan_amount = parse(Float64, readline())
            if loan_amount <= 0
                println("❌ Must be greater than 0.")
            end
        catch
            println("❌ Please enter a valid number.")
        end
    end

    monthly_term = 0
    while !(monthly_term in (36, 60))
        println("Enter monthly term (choose 36 or 60 months):")
        try
            monthly_term = parse(Int, readline())
            if !(monthly_term in (36, 60))
                println("❌ Must be 36 or 60.")
            end
        catch
            println("❌ Please enter 36 or 60.")
        end
    end

    valid_purposes = ["car", "educational", "house"]
    purpose = ""
    while !(lowercase(purpose) in valid_purposes)
        println("Enter purpose (choose from: car, educational, house):")
        purpose = readline()
        if !(lowercase(purpose) in valid_purposes)
            println("❌ Invalid choice.")
        end
    end

    return (annual_income, loan_amount, monthly_term, lowercase(purpose))
end
src/calculations.jl

julia
Copy code
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
