# Cleaned, single-flow script for correlation analysis and simple advisor
using CSV, DataFrames, Statistics, StatsBase

function find_dataset()
    candidates = ["Bank loan tool data - financial_loan.csv", "loan_data.csv", "financial_loan.csv"]
    for f in candidates
        if isfile(f)
            return f
        end
    end
    error("No dataset found. Place CSV in project root and re-run.")
end

function clean_data!(df::DataFrame)
    # Normalize column names and values we care about
    if :monthly_term in names(df)
        try
            df.monthly_term = parse.(Int, replace.(strip.(string.(df.monthly_term)), r"[^0-9]" => ""))
        catch
            # leave as-is
        end
    end
    if :purpose in names(df)
        df.purpose = lowercase.(strip.(string.(df.purpose)))
    end
    if :debt_to_income_ratio in names(df) && !(:dti in names(df))
        try
            df.dti = Float64.(df.debt_to_income_ratio)
        catch
            try
                df.dti = parse.(Float64, replace.(string.(df.debt_to_income_ratio), r"[^0-9\.]" => ""))
            catch
            end
        end
    end
    return df
end

function parse_rate(x)
    if x === missing || x === nothing
        return NaN
    elseif x isa Number
        return Float64(x)
    else
        s = strip(string(x))
        s = replace(s, "%" => "")
        s = replace(s, r"[^0-9\.]" => "")
        try
            return parse(Float64, s)
        catch
            return NaN
        end
    end
end

function avg_rate_by_grade(df::DataFrame)
    # detect int rate column by several possible names (case-insensitive)
    candidates = [:int_rate, :"int rate", :interest_rate, :intRate]
    col = nothing
    for c in candidates
        if c in names(df)
            col = c
            break
        end
    end
    if col === nothing
        # try a case-insensitive search
        for c in names(df)
            if occursin("int", lowercase(string(c))) && occursin("rate", lowercase(string(c)))
                col = c
                break
            end
        end
    end
    if col === nothing
        error("Dataset missing `int_rate` column")
    end
    df.int_rate_parsed = parse_rate.(df[!, col])
    g = groupby(df, :grade)
    res = combine(g, :int_rate_parsed => (x->mean(skipmissing(filter(!isnan, x)))) => :avg_int_rate)
    return sort(res, :grade)
end

function compute_correlation(df::DataFrame, numeric_cols::Vector{Symbol})
    # helper to coerce a column to Float64 vector (non-parsable entries become missing)
    function tofloatcol(colvals)
        out = Float64[]
        for v in colvals
            s = replace(string(v), '%'=>"")
            s = replace(s, r"[^0-9\.-]"=>"")
            if isempty(s)
                push!(out, NaN)
            else
                try
                    push!(out, parse(Float64, s))
                catch
                    push!(out, NaN)
                end
            end
        end
        return out
    end

    n = length(numeric_cols)
    mat = zeros(Float64, n, n)
    for i in 1:n
        for j in 1:n
            a = numeric_cols[i]
            b = numeric_cols[j]
            if a in names(df) && b in names(df)
                x = tofloatcol(df[!, a])
                y = tofloatcol(df[!, b])
                # replace NaN with missing for cor calculation
                xmiss = map(v->isnan(v) ? missing : v, x)
                ymiss = map(v->isnan(v) ? missing : v, y)
                try
                    mat[i, j] = cor(skipmissing(xmiss), skipmissing(ymiss))
                catch
                    mat[i, j] = NaN
                end
            else
                mat[i, j] = NaN
            end
        end
    end
    return mat
end

function print_correlation_summary(cor_matrix, numeric_cols)
    max_corr, max_pair = -Inf, ("", "")
    min_corr, min_pair = Inf, ("", "")
    n = length(numeric_cols)
    for i in 1:n, j in i+1:n
        c = cor_matrix[i, j]
        if c > max_corr
            max_corr = c
            max_pair = (string(numeric_cols[i]), string(numeric_cols[j]))
        end
        if c < min_corr
            min_corr = c
            min_pair = (string(numeric_cols[i]), string(numeric_cols[j]))
        end
    end
    println("Strongest positive correlation: $(max_pair) = $(round(max_corr, digits=3))")
    println("Strongest negative correlation: $(min_pair) = $(round(min_corr, digits=3))")
end

function find_similar_applicants(df::DataFrame; purpose="car", annual_income=60000.0, loan_amount=12000.0, home_ownership="RENT", dti=0.2)
    if :debt_to_income_ratio in names(df)
        df_dti = Float64.(replace.(string.(df.debt_to_income_ratio), r"[^0-9\.]"=>""))
        df[!, :dti_tmp] = df_dti
    elseif :dti in names(df)
        df[!, :dti_tmp] = Float64.(df.dti)
    else
        df[!, :dti_tmp] = fill(NaN, nrow(df))
    end
    sim = filter(row -> lowercase(string(row.purpose)) == lowercase(purpose) &&
                  abs(float(row.annual_income) - annual_income) < 15000 &&
                  abs(float(row.loan_dollar_amount) - loan_amount) < 5000 &&
                  (isempty(string(row.home_ownership)) || uppercase(string(row.home_ownership)) == uppercase(home_ownership)) &&
                  !isnan(row.dti_tmp) && abs(row.dti_tmp - dti) < 0.1,
                  df)
    return sim
end

function advisor_demo(df::DataFrame)
    demo = Dict(
        :purpose => "car",
        :annual_income => 60000.0,
        :loan_amount => 12000.0,
        :home_ownership => "RENT",
        :dti => 0.2
    )
    sim = find_similar_applicants(df; purpose=demo[:purpose], annual_income=demo[:annual_income], loan_amount=demo[:loan_amount], home_ownership=demo[:home_ownership], dti=demo[:dti])
    if isempty(sim)
        println("Demo advisor: no similar applicants found for demo inputs.")
    else
        println("Demo advisor: found $(nrow(sim)) similar applicants.")
        if :grade in names(sim)
            println("Most common grade among similar applicants: ", mode(sim.grade))
        end
        if :loan_status in names(sim)
            println("Most common loan status: ", mode(sim.loan_status))
        end
    end
end

function main()
    csv = find_dataset()
    println("Loading dataset: ", csv)
    df = CSV.read(csv, DataFrame)
    clean_data!(df)

    numeric_cols = [:annual_income, :loan_dollar_amount, :debt_to_income_ratio, :monthly_installment, :int_rate, :total_accounts, :total_payment]
    existing_numeric = [c for c in numeric_cols if c in names(df)]
    if isempty(existing_numeric)
        println("No numeric columns found for correlation analysis.")
    else
        cor_matrix = compute_correlation(df, existing_numeric)
        println("\nCorrelation matrix for: ", existing_numeric)
        show(cor_matrix)
        println()
        print_correlation_summary(cor_matrix, existing_numeric)
    end

    println("\nAverage interest rate by grade:")
    try
        tbl = avg_rate_by_grade(df)
        for r in eachrow(tbl)
            rate = r.avg_int_rate
            rate_pct = rate <= 1.0 ? rate*100 : rate
            println("Grade $(r.grade) => $(round(rate_pct, digits=2))%")
        end
    catch e
        println("Could not compute interest rates by grade: ", e)
    end

    println("\nRunning advisor demo (non-interactive)...")
    advisor_demo(df)
end

main()
