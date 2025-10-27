using Statistics

# Try to use PrettyTables if available; otherwise fall back to a simple ASCII table
const HAS_PRETTYTABLES = try
    @eval import PrettyTables
    true
catch
    false
end

function format_number_with_commas(n::Real; digits=2)::String
    if isnan(n) || isinf(n)
        return "N/A"
    end
    rounded = round(n; digits=digits)
    s = string(rounded)
    if occursin('.', s)
        parts = split(s, '.', limit=2)
        int_part = parts[1]
        dec_part = "." * rpad(parts[2], digits, '0')
    else
        int_part = s
        dec_part = "." * repeat("0", digits)
    end
    int_part = replace(int_part, r"(\d)(?=(\d{3})+(?!\d))" => s"\1,")
    return int_part * dec_part
end

format_currency(val::Real; digits=2)::String = "\$" * format_number_with_commas(val; digits=digits)

function compute_column_widths(headers::Vector{String}, rows::Vector{Vector{String}})
    widths = [length(h) for h in headers]
    for row in rows
        @assert length(row) == length(headers)
        for (i, cell) in enumerate(row)
            widths[i] = max(widths[i], length(cell))
        end
    end
    return widths
end

make_separator(char::Char, widths::Vector{Int}) = "+" * join([repeat(string(char), w + 2) for w in widths], "+") * "+"

function format_table_row(row::Vector{String}, widths::Vector{Int}, alignments::Vector{Symbol})
    cells = Vector{String}(undef, length(row))
    for i in eachindex(row)
        cell = row[i]
        width = widths[i]
        alignment = alignments[i]
        padded = alignment === :right ? lpad(cell, width) : rpad(cell, width)
        cells[i] = " " * padded * " "
    end
    return "|" * join(cells, "|") * "|"
end

function print_table(headers::Vector{String}, rows::Vector{Vector{String}}; alignments::Union{Nothing, Vector{Symbol}}=nothing)
    if HAS_PRETTYTABLES
        # PrettyTables expects a matrix-like table. Convert rows -> Matrix{String} (nrows x ncols).
        ncols = length(headers)
        data_mat = if isempty(rows)
            Matrix{String}(undef, 0, ncols)
        else
            # Each row vector turned into a 1 x ncols matrix, then vcat together.
            reduce(vcat, (permutedims(r) for r in rows))
        end

        # Normalize alignments: ensure vector length == ncols (fallback to left)
        alignment_pt = if alignments === nothing
            :l
        else
            als = map(a -> a === :right ? :r : :l, alignments)
            if length(als) != ncols
                # Fallback to uniform left alignment if mismatch to avoid errors
                :l
            else
                als
            end
        end
        # PrettyTables v3 expects headers via `column_labels` keyword.
        PrettyTables.pretty_table(data_mat; column_labels=headers, alignment=alignment_pt)
    else
        # Fallback ASCII renderer
        if alignments === nothing
            alignments = fill(:left, length(headers))
        end
        header_alignments = fill(:left, length(headers))
        widths = compute_column_widths(headers, rows)
        top_border = make_separator('-', widths)
        header_border = make_separator('=', widths)
        println(top_border)
        println(format_table_row(headers, widths, header_alignments))
        println(header_border)
        for row in rows
            println(format_table_row(row, widths, alignments))
        end
        println(top_border)
    end
end
