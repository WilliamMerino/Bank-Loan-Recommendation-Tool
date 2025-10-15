using DataFrames

"""
    compute_quality_metrics(df::AbstractDataFrame) -> NamedTuple

Summarise dataset quality by counting missing values and validation issues.
The returned named tuple contains:

* `row_count` — total number of rows analysed
* `missing_counts` — dictionary mapping each column to the number of missings
* `missing_columns` — list of column symbols with at least one missing entry
* `validation_issues` — total number of issues reported by `validate_dataset`
* `affected_rows` — number of rows that triggered at least one validation issue
* `issue_rate` — average number of validation issues per row
"""
function compute_quality_metrics(df::AbstractDataFrame)
    issues = validate_dataset(df)
    missing_counts = Dict{Symbol,Int}()
    for col in propertynames(df)
        column = df[!, col]
        missing_counts[col] = count(ismissing, column)
    end
    missing_columns = sort([col for (col, v) in missing_counts if v > 0])
    total_issue_messages = sum(length(entry.issues) for entry in issues)
    affected_rows = length(issues)
    rows = nrow(df)
    issue_rate = rows == 0 ? 0.0 : total_issue_messages / rows
    return (
        row_count = rows,
        missing_counts = missing_counts,
        missing_columns = missing_columns,
        validation_issues = total_issue_messages,
        affected_rows = affected_rows,
        issue_rate = issue_rate,
    )
end
