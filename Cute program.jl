# ===========================
# 0. Install Required Packages
# ===========================
using Pkg
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("Statistics")
Pkg.add("JSON")
Pkg.add("Plots")
Pkg.add("ArgParse")  # Optional, not used in this script but available for CLI

# ===========================
# 1. Import Packages
# ===========================
using CSV
using DataFrames
using Statistics
using JSON
using Plots

# ===========================
# 2. Data Loading & Cleaning
# ===========================
function load_and_clean_data(csv_file::String, numeric_cols::Vector{Symbol})
    df = CSV.read(csv_file, DataFrame)
    for col in numeric_cols
        try
            df[!, col] = parse.(Float64, df[!, col]; raise=false)
        catch
            println("Warning: Could not parse column $col to Float64.")
        end
    end
    df_clean = dropmissing(df, numeric_cols)
    return df_clean
end

# ===========================
# 3. Correlation Analysis
# ===========================
function compute_and_save_correlation(df_clean::DataFrame, numeric_cols::Vector{Symbol}, out_json::String)
    cor_matrix = cor(Matrix(df_clean[:, numeric_cols]))
    cor_data = Dict(
        "columns" => string.(numeric_cols),
        "correlation_matrix" => cor_matrix
    )
    open(out_json, "w") do io
        JSON.print(io, cor_data)
    end
    return cor_matrix
end

function print_correlation_summary(cor_matrix, numeric_cols)
    max_corr, min_corr = 0.0, 1.0
    max_pair, min_pair = ("", ""), ("", "")
    for i in 1:length(numeric_cols), j in 1:length(numeric_cols)
        if i != j
            c = cor_matrix[i, j]
            if abs(c) > abs(max_corr)
                max_corr = c
                max_pair = (string(numeric_cols[i]), string(numeric_cols[j]))
            end
            if abs(c) < abs(min_corr)
                min_corr = c
                min_pair = (string(numeric_cols[i]), string(numeric_cols[j]))
            end
        end
    end
    println("\nStrongest correlation: $max_pair = $max_corr")
    println("Weakest correlation: $min_pair = $min_corr")
end

# ===========================
# 4. User Analysis Tool (REPL)
# ===========================
function analyze_user_input(user_inputs::Dict, columns, cor_matrix)
    println("\n=== Correlation Analysis for Your Inputs ===")
    for (var, value) in user_inputs
        idx = findfirst(==(var), columns)
        if isnothing(idx)
            println("Variable $var not found in correlation matrix.")
            continue
        end
        println("\nCorrelations for $var:")
        for (j, col) in enumerate(columns)
            if col != var
                corr = cor_matrix[idx, j]
                print("  $col: $(round(corr, digits=3))")
                if abs(corr) > 0.7
                    println(" (Strong relationship)")
                elseif abs(corr) > 0.3
                    println(" (Moderate relationship)")
                else
                    println(" (Weak relationship)")
                end
            end
        end
    end
end

function interactive_tool(columns, cor_matrix)
    println("\n=== Interactive Correlation Tool ===")
    println("Enter variable names (from: $(columns)) and values (comma-separated, e.g. annual_income=50000,loan_dollar_amount=10000)")
    println("Type 'exit' to quit.")
    while true
        print("\nYour input: ")
        user_line = readline()
        if lowercase(strip(user_line)) == "exit"
            println("Exiting tool.")
            break
        end
        user_inputs = Dict{String, Float64}()
        for pair in split(user_line, ',')
            if occursin("=", pair)
                k, v = split(pair, '=')
                k = strip(k)
                v = tryparse(Float64, strip(v))
                if v !== nothing
                    user_inputs[k] = v
                else
                    println("Invalid value for $k, skipping.")
                end
            end
        end
        analyze_user_input(user_inputs, columns, cor_matrix)
    end
end

# ===========================
# 5. Visualization
# ===========================
function plot_heatmap(cor_matrix, columns)
    heatmap(
        cor_matrix,
        xticks=(1:length(columns), columns),
        yticks=(1:length(columns), columns),
        c=:coolwarm,
        title="Correlation Matrix Heatmap"
    )
end

# ===========================
# 6. Main Script Logic
# ===========================
function main()
    # --- File and columns setup ---
    csv_file = "CSV/Bank loan tool data - financial_loan.csv"
    numeric_cols = [
        :annual_income, :loan_dollar_amount, :debt_to_income_ratio,
        :monthly_installment, :int_rate, :total_accounts, :total_payment
    ]
    out_json = "correlation_matrix.json"

    # --- Load and clean data ---
    df_clean = load_and_clean_data(csv_file, numeric_cols)

    # --- Compute and save correlation matrix ---
    cor_matrix = compute_and_save_correlation(df_clean, numeric_cols, out_json)
    columns = string.(numeric_cols)

    # --- Print correlation matrix and summary ---
    println("\n=== Correlation Matrix ===")
    println(cor_matrix)
    print_correlation_summary(cor_matrix, numeric_cols)

    # --- Interactive user tool ---
    interactive_tool(columns, cor_matrix)

    # --- Visualization ---
    println("\nDo you want to plot the correlation matrix heatmap? (y/n)")
    ans = readline()
    if lowercase(strip(ans)) == "y"
        plot_heatmap(cor_matrix, columns)
    end
end

# ===========================
# 7. Run Main
# ===========================
main()

using CSV, DataFrames, Statistics, JSON

function get_user_input(prompt::String, parse_func)
    while true
        print(prompt)
        input = readline()
        val = parse_func(input)
        if val !== nothing
            return val
        else
            println("Invalid input. Please try again.")
        end
    end
end

function main()
    println("Welcome to the Loan Application Advisor!")
    println("Please answer a few questions about your loan inquiry.\n")

    # Prompt for user details
    purpose = get_user_input("What is the purpose of your loan? (e.g., car, educational): ", x->strip(x))
    annual_income = get_user_input("What is your annual income (in USD)? ", x->tryparse(Float64, strip(x)))
    loan_amount = get_user_input("What is the loan amount you want (in USD)? ", x->tryparse(Float64, strip(x)))
    monthly_term = get_user_input("What is the loan term? (e.g., 36 months): ", x->strip(x))
    home_ownership = get_user_input("What is your home ownership status? (MORTGAGE, RENT, OWN): ", x->strip(x))
    debt_to_income = get_user_input("What is your debt-to-income ratio (e.g., 0.15)? ", x->tryparse(Float64, strip(x)))

    # Load data and correlation matrix (done in background)
    df = CSV.read("CSV/Bank loan tool data - financial_loan.csv", DataFrame)
    # (Assume you have already saved a correlation matrix and/or trained a model)
    # For demo, we'll just compare to similar applicants in the dataset

    # Find similar applicants (simple filter)
    similar = filter(row -> 
        row.purpose == purpose &&
        abs(row.annual_income - annual_income) < 10000 &&
        abs(row.loan_dollar_amount - loan_amount) < 2000 &&
        row.home_ownership == home_ownership &&
        abs(row.debt_to_income_ratio - debt_to_income) < 0.05,
        df
    )

    # Grade logic (demo: use most common grade among similar applicants)
    grade = isempty(similar) ? "N/A" : mode(similar.grade)
    status = isempty(similar) ? "N/A" : mode(similar.loan_status)

    println("\n--- Loan Application Summary ---")
    if isempty(similar)
        println("We couldn't find many applicants with similar profiles in our data.")
        println("Please check your inputs or try again with different values.")
    else
        println("Based on similar applicants in our data:")
        println("  - Most common loan grade: $grade")
        println("  - Most common loan outcome: $status")
        println("  - Number of similar applicants found: $(nrow(similar))")
        println("  - Example: $(first(similar, 1))")
    end
    println("\nThank you for using the Loan Application Advisor!")
end

main()
