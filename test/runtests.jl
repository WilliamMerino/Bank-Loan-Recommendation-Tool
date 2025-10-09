using Test
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using BankLoanRecommendationTool

include("test_formatting.jl")
include("test_data.jl")
include("test_grading.jl")
include("test_similarity.jl")
include("test_reporting.jl")

