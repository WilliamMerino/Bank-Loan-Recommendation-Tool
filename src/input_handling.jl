function get_user_input()
    # Helper to mitigate first-line swallow in some REPLs (e.g., VS Code Run)
    read_input(msg) = begin
        println(msg)
        flush(stdout)
        # Try up to 3 times with a short pause to catch stray newlines from host REPLs
        s = ""
        for _ in 1:3
            s = try
                strip(readline())
            catch
                ""
            end
            if !isempty(s)
                break
            end
            sleep(0.05)
        end
        return s
    end
    # Detect non-interactive contexts (e.g., VS Code Run button)
    noninteractive = (haskey(ENV, "VSCODE_PID") && get(ENV, "BLRT_ALLOW_PROMPT", "0") != "1") || get(ENV, "BLRT_NONINTERACTIVE", "0") == "1"
    if noninteractive
        # Pull values from environment or use sensible defaults, and echo to user
        annual_income = try parse(Float64, get(ENV, "BLRT_ANNUAL_INCOME", "60000")) catch; 60000.0 end
        loan_amount = try parse(Float64, get(ENV, "BLRT_LOAN_AMOUNT", "10000")) catch; 10000.0 end
        monthly_term = try parse(Int, get(ENV, "BLRT_TERM", "60")) catch; 60 end
        purpose = lowercase(get(ENV, "BLRT_PURPOSE", "car"))
        emp_length_years = try parse(Int, get(ENV, "BLRT_EMP_YEARS", "5")) catch; 5 end
        home_ownership = uppercase(get(ENV, "BLRT_HOME", "MORTGAGE"))
        verification_status = get(ENV, "BLRT_VERIFY", "Verified")
        total_accounts = try parse(Int, get(ENV, "BLRT_TOTAL_ACCOUNTS", "10")) catch; 10 end
        println("Non-interactive mode: using income=$(annual_income), loan=$(loan_amount), term=$(monthly_term), purpose=$(purpose), emp_years=$(emp_length_years), home=$(home_ownership), verify=$(verification_status), total_accts=$(total_accounts)")
        return (
            annual_income, loan_amount, monthly_term, purpose,
            emp_length_years, home_ownership, verification_status, total_accounts,
        )
    end
    annual_income = -1.0
    while annual_income <= 0
        inp = read_input("Enter annual income (positive number, e.g., 40000) - Please verify response is correct (type in twice):")
        try
            annual_income = parse(Float64, inp)
            if annual_income <= 0
                println("❌ Must be greater than 0.")
            end
        catch
            println("❌ Please verify the number input is correct.")
        end
    end

    loan_amount = -1.0
    while loan_amount <= 0
        inp = read_input("Enter loan dollar amount (positive number, e.g., 12000):")
        try
            loan_amount = parse(Float64, inp)
            if loan_amount <= 0
                println("❌ Must be greater than 0.")
            end
        catch
            println("❌ Please enter a valid number.")
        end
    end

    monthly_term = 0
    while !(monthly_term in (36, 60))
        inp = read_input("Enter monthly term (choose 36 or 60 months):")
        try
            monthly_term = parse(Int, inp)
            if !(monthly_term in (36, 60))
                println("❌ Must be 36 or 60.")
            end
        catch
            println("❌ Please enter 36 or 60.")
        end
    end

    valid_purposes = ["car", "educational", "home improvement"]
    purpose = ""
    while !(lowercase(purpose) in valid_purposes)
        purpose = read_input("Enter purpose (choose from: car, educational, home improvement):")
        if !(lowercase(purpose) in valid_purposes)
            println("❌ Invalid choice.")
        end
    end

    # Employment length (years, 0–10)
    emp_length_years = -1
    while emp_length_years < 0 || emp_length_years > 10
        inp = read_input("Enter employment length in years (0 to 10, where 10 means 10+):")
        try
            emp_length_years = parse(Int, inp)
            if emp_length_years < 0 || emp_length_years > 10
                println("❌ Must be an integer between 0 and 10.")
            end
        catch
            println("❌ Please enter an integer between 0 and 10.")
        end
    end

    # Home ownership (OWN/MORTGAGE/RENT)
    valid_home = ["own","mortgage","rent"]
    home_ownership = ""
    while !(lowercase(home_ownership) in valid_home)
        home_ownership = read_input("Enter home ownership (own, mortgage, rent):")
        if !(lowercase(home_ownership) in valid_home)
            println("❌ Invalid choice.")
        end
    end

    # Income verification status (clean input + normalize)
    function _parse_verify(s)
        t = lowercase(strip(s))
        if t in ("1","v","ver","verified")
            return "Verified"
        elseif t in ("2","sv","source verified","source-verified","sourceverified")
            return "Source Verified"
        elseif t in ("3","nv","not verified","not-verified","notverified","no")
            return "Not Verified"
        else
            return nothing
        end
    end
    verification_status = ""
    while true
        println("Verification status options:")
        println("- Verified: You provided documents (e.g., pay stubs, W-2, tax returns) that the lender reviewed.")
        println("- Source Verified: The lender verified income directly with a trusted source (e.g., employer, payroll provider, transcripts). Strongest confirmation.")
        println("- Not Verified: Income was not independently confirmed.")
        inp = read_input("Enter verification status: [1] Verified, [2] Source Verified, [3] Not Verified")
        parsed = _parse_verify(inp)
        if parsed === nothing
            println("❌ Invalid choice. Type 1/2/3 or a valid label.")
        else
            verification_status = parsed
            break
        end
    end

    # Total accounts on file (non-negative int)
    total_accounts = -1
    while total_accounts < 0
        inp = read_input("Enter total accounts on file (non-negative integer, e.g., 12):")
        try
            total_accounts = parse(Int, inp)
            if total_accounts < 0
                println("❌ Must be non-negative.")
            end
        catch
            println("❌ Please enter a non-negative integer.")
        end
    end

    return (
        annual_income,
        loan_amount,
        monthly_term,
        lowercase(purpose),
        emp_length_years,
        uppercase(home_ownership),
        verification_status,
        total_accounts,
    )
end
