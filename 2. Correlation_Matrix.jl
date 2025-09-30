function compute_correlation(df::DataFrame, numeric_cols::Vector{Symbol})
    # helper to coerce a column to Float64 vector (non-parsable entries become missing)
    function tofloatcol(colvals)
        out = Float64[]
        for v in colvals
            s = replace(string(v), '%' => "")
            s = replace(s, r"[^0-9\.-]" => "")
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
                xmiss = map(v -> isnan(v) ? missing : v, x)
                ymiss = map(v -> isnan(v) ? missing : v, y)
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
