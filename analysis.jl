
# Minimal data loading and inspection
using CSV, DataFrames

csv_file = joinpath(@__DIR__, "Bank loan tool data - financial_loan.csv")
if !isfile(csv_file)
	println("ERROR: CSV file not found at ", csv_file)
	exit(1)
end

println("Reading CSV: ", csv_file)
df = CSV.read(csv_file, DataFrame)

println("Loaded DataFrame with ", size(df,1), " rows and ", size(df,2), " columns.")
println("\nFirst 5 rows:")
display(first(df,5))

println("\n\nSummary (describe):")
display(describe(df))

# End of simple loader
