module BankLoanRecommendationTool

export load_data, normalize_columns,
       compute_applicant_dti, derive_purpose_thresholds, assign_grade,
       compute_risk_score,
       safe_mean, top_similar_by_dti,
        format_number_with_commas, format_currency, print_table,
       make_recommendation,
       run_tool,
       start

include("data.jl")
include("grading.jl")
include("formatting.jl")
include("similarity.jl")
include("reporting.jl")

"""
    run_tool()

Convenience launcher to start the interactive CLI from any context
(including when this file is included into an existing REPL).
"""
function run_tool()
    # Always re-include to pick up latest edits in src/main.jl
    include(joinpath(@__DIR__, "main.jl"))
    return Base.invokelatest(main)
end
start() = run_tool()

end # module

# Auto-start behavior
if abspath(PROGRAM_FILE) == @__FILE__
    # Executed as a script (e.g., `julia src/BankLoanRecommendationTool.jl`)
    BankLoanRecommendationTool.run_tool()
elseif isinteractive()
    # Included into an interactive REPL (e.g., VS Code Run button)
    try
        BankLoanRecommendationTool.run_tool()
    catch err
        @warn "Auto-start failed; call BankLoanRecommendationTool.start()" err
    end
end
