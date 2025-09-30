# --- Step 1: Get user input with validation ---
function get_user_input()
    annual_income = -1.0
    while annual_income <= 0
        println("Enter annual income (positive number, e.g., 60000):")
        try
            annual_income = parse(Float64, readline())
            if annual_income <= 0
                println("❌ Invalid input. Must be greater than 0.")
            end
        catch
            println("❌ Invalid input. Please enter a number, e.g., 60000")
        end
    end

    loan_amount = -1.0
    while loan_amount <= 0
        println("Enter loan dollar amount (positive number, e.g., 12000):")
        try
            loan_amount = parse(Float64, readline())
            if loan_amount <= 0
                println("❌ Invalid input. Must be greater than 0.")
            end
        catch
            println("❌ Invalid input. Please enter a number, e.g., 12000")
        end
    end

    monthly_term = 0
    while !(monthly_term in (36, 60))
        println("Enter monthly term (choose 36 or 60 months):")
        try
            monthly_term = parse(Int, readline())
            if !(monthly_term in (36, 60))
                println("❌ Invalid choice. Must be 36 or 60.")
            end
        catch
            println("❌ Invalid input. Please enter 36 or 60.")
        end
    end

    valid_purposes = ["car", "educational", "house"]
    purpose = ""
    while !(lowercase(purpose) in valid_purposes)
        println("Enter purpose (choose from: car, educational, or house):")
        purpose = readline()
        if !(lowercase(purpose) in valid_purposes)
            println("❌ Invalid choice. Please enter car, educational, or house.")
        end
    end

    return (annual_income, loan_amount, monthly_term, lowercase(purpose))
end

# --- Step 2: Compute Monthly DTI ---
function compute_dti(annual_income, loan_amount, monthly_term)
    monthly_income = annual_income / 12
    monthly_payment = loan_amount / monthly_term
    return monthly_payment / monthly_income
end
