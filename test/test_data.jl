using Test
using DataFrames
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using BankLoanRecommendationTool

@testset "data normalization" begin
    df = DataFrame(annual_income=[60000.0], loan_dollar_amount=[12000.0], term=[60], purpose=["Car"], grade=["b"])
    ndf = normalize_columns(df)
    @test :loan_amount in propertynames(ndf)
    @test ndf.purpose[1] == "car"
    @test ndf.grade[1] == "B"
    @test :debt_to_income_ratio in propertynames(ndf)
end
