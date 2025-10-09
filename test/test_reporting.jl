using Test
using BankLoanRecommendationTool

@testset "reporting" begin
    @test occursin("Recommended", make_recommendation("A"))
    @test occursin("Medium", make_recommendation("C"))
    @test occursin("High", make_recommendation("G"))
end

