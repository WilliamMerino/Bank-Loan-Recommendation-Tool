#!/usr/bin/env julia
using CSV, DataFrames, Statistics

function find_dataset()
    candidates = ["Bank loan tool data - financial_loan.csv", "loan_data.xlsx", "0. loan_data.csv", "financial_loan.csv"]
    for f in candidates
        if isfile(f)
            return f 
        end
    end
    error("No dataset found. Place a CSV/XLSX dataset in the project folder and re-run.")
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
    # Detect int-rate column (allow for String or Symbol names, case-insensitive)
    col = nothing
    candidates = [:int_rate, :"int rate", :interest_rate, :intRate]
    for c in candidates
        if c in names(df)
            col = c
            break
        end
    end
    if col === nothing
        # case-insensitive scan
        for c in names(df)
            lc = lowercase(string(c))
            if occursin("int", lc) && occursin("rate", lc)
                col = c
                break
            end
        end
    end
    if col === nothing
        error("Dataset does not contain an `int_rate` column.")
    end
    df.int_rate_parsed = parse_rate.(df[!, col])

    # group by `grade` and compute mean int_rate (skip NaN)
    g = groupby(df, :grade)
    res = combine(g, :int_rate_parsed => (x->mean(skipmissing(filter(!isnan, x)))) => :avg_int_rate)
    return res
end

function main()
    path = find_dataset()
    println("Loading dataset: ", path)
    df = CSV.read(path, DataFrame)

    tbl = avg_rate_by_grade(df)

    if length(ARGS) >= 1
        grade = uppercase(ARGS[1])
        row = filter(r -> uppercase(string(r.grade)) == grade, tbl)
        if nrow(row) == 0
            println("No data for grade '", grade, "'. Available grades: ", join(sort(unique(string.(tbl.grade))), ", "))
        else
            rate = row.avg_int_rate[1]
            # If parsed values were decimals (e.g., 0.15), detect and scale to percent
            if rate <= 1.0
                rate_pct = rate * 100
            else
                rate_pct = rate
            end
            println("Average interest rate for grade ", grade, ": ", round(rate_pct, digits=2), "%")
        end
    else
        println("Average interest rate by grade:")
        for r in eachrow(sort(tbl, :grade))
            rate = r.avg_int_rate
            if rate <= 1.0
                rate_pct = rate * 100
            else
                rate_pct = rate
            end
            println("Grade ", r.grade, " => ", round(rate_pct, digits=2), "%")
            println("To get the rate for a specific grade, run: julia find_interest_rate.jl <grade>")
        end
    end
end

main()
