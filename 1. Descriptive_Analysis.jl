# 1. Descriptive_Analysis.jl

using CSV
using DataFrames

const CSV_FILENAME = "loan_data.csv"
const CSV_PATH = joinpath(@__DIR__, CSV_FILENAME)

println("Script dir: ", @__DIR__)
println("Working dir: ", pwd())
println("Looking for CSV at: ", CSV_PATH)

if !isfile(CSV_PATH)
    println("ERROR: CSV file not found.")
    println("Files in script directory:")
    for f in readdir(@__DIR__)
        println(" - ", f)
    end
    error("CSV file missing at expected path: " * CSV_PATH)
end

println("Reading CSV: ", CSV_PATH)
df = CSV.read(CSV_PATH, DataFrame)

println("Loaded DataFrame with ", size(df, 1), " rows and ", size(df, 2), " columns.")
println("\nFirst 5 rows:")
display(first(df, 5))

println("\n\nSummary (describe):")
display(describe(df))
