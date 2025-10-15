using Dates

"""
    format_validation_report(issues; max_rows=nothing) -> String

Pretty-print validation issues as a multi-line string. The input `issues`
should match the result returned by `validate_dataset`, i.e. a vector of
named tuples with fields `row` and `issues`. When `max_rows` is provided,
only that many rows are included and an ellipsis line is appended.
"""
function format_validation_report(issues; max_rows::Union{Nothing,Int}=nothing)
    isempty(issues) && return "No validation issues detected."
    io = IOBuffer()
    limit = isnothing(max_rows) ? length(issues) : min(length(issues), max_rows)
    println(io, "Validation issues:")
    for entry in Iterators.take(issues, limit)
        println(io, "- Row $(entry.row):")
        for msg in entry.issues
            println(io, "    • $(msg)")
        end
    end
    if !isnothing(max_rows) && length(issues) > max_rows
        println(io, "… and $(length(issues) - max_rows) more rows with issues.")
    end
    return String(take!(io))
end

"""
    save_validation_report(path::AbstractString, issues; kwargs...) -> String

Persist a formatted validation report to `path`. By default the file is
overwritten; set `append=true` to add to the existing file. When
`include_timestamp=true`, the report is prefixed with an ISO-8601 timestamp.
Returns the written `path`.
"""
function save_validation_report(path::AbstractString, issues;
                                max_rows::Union{Nothing,Int}=nothing,
                                append::Bool=false,
                                include_timestamp::Bool=true)
    report = format_validation_report(issues; max_rows=max_rows)
    timestamp = include_timestamp ? Dates.format(Dates.now(), Dates.dateformat"yyyy-mm-ddTHH:MM:SS") : ""
    open(path, append ? "a" : "w") do io
        if include_timestamp
            println(io, timestamp)
        end
        println(io, report)
    end
    return path
end
