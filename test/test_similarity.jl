using Test
using DataFrames
using BankLoanRecommendationTool

@testset "similarity" begin
    cohort = DataFrame(debt_to_income_ratio=[0.05, 0.08, 0.12, 0.2], purpose=["car","car","car","car"])
    sims = top_similar_by_dti(cohort, 0.1; top_n=2)
    @test nrow(sims) == 2
end

