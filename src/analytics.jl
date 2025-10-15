using Statistics
using DataFrames

"""
    grade_distribution(df::AbstractDataFrame) -> NamedTuple

Compute the frequency of each loan grade present in `df`. Returns a named tuple
with the grade counts and the number of missing entries. Grades are normalized
to uppercase strings before tallying.
"""
function grade_distribution(df::AbstractDataFrame)
    hasproperty(df, :grade) || throw(ArgumentError("dataset missing `grade` column"))
    counts = Dict{String,Int}()
    missing_count = 0
    for value in df[!, :grade]
        if ismissing(value)
            missing_count += 1
            continue
        end
        grade = uppercase(String(value))
        counts[grade] = get(counts, grade, 0) + 1
    end
    return (counts=counts, missing=missing_count)
end

"""
    purpose_summary(df::AbstractDataFrame; min_count::Int=1) -> DataFrame

Aggregate loan statistics by purpose. Returns a DataFrame with one row per
purpose and the following columns:

* `purpose` — normalized lowercase purpose string
* `count` — number of rows contributing to the aggregate
* `avg_loan_amount` — mean loan amount (ignoring missing values)
* `avg_debt_to_income_ratio` — mean DTI ratio (ignoring missing values)
* `avg_int_rate` — mean interest rate in percentage points (0–100 scale)

Purposes with fewer than `min_count` rows are filtered out. Missing purpose
values are ignored.
"""
function purpose_summary(df::AbstractDataFrame; min_count::Int=1)
    min_count >= 1 || throw(ArgumentError("min_count must be >= 1 (got $(min_count))"))
    required = (:purpose, :loan_amount, :debt_to_income_ratio, :int_rate)
    for col in required
        hasproperty(df, col) || throw(ArgumentError("dataset missing `$(col)` column"))
    end

    clean_idx = findall(x -> !ismissing(x), df[!, :purpose])
    if isempty(clean_idx)
        return DataFrame(purpose=String[], count=Int[], avg_loan_amount=Float64[],
                         avg_debt_to_income_ratio=Float64[], avg_int_rate=Float64[])
    end

    sub = df[clean_idx, :]
    # Normalize purpose to lowercase strings for consistent grouping
    purposes = lowercase.(String.(sub[!, :purpose]))
    sub = copy(sub)
    sub[!, :purpose] = purposes

    grouped = groupby(sub, :purpose)
    mean_skip(vals) = begin
        total = 0.0
        count = 0
        for v in vals
            if !ismissing(v)
                total += float(v)
                count += 1
            end
        end
        count == 0 ? NaN : total / count
    end
    agg = combine(grouped) do g
        (
            count = nrow(g),
            avg_loan_amount = mean_skip(g[!, :loan_amount]),
            avg_debt_to_income_ratio = mean_skip(g[!, :debt_to_income_ratio]),
            avg_int_rate = mean_skip(g[!, :int_rate]) * 100,
        )
    end

    filter!(row -> row.count >= min_count, agg)
    sort!(agg, [:count, :purpose], rev=[true, false])
    return agg
end
