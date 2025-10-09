using Test
using DataFrames
using BankLoanRecommendationTool

@testset "grading" begin
    dti = compute_applicant_dti(60000.0, 12000.0, 60) # 0.0333...
    @test 0.03 < dti < 0.04

    cohort = DataFrame(grade=["A","B","C"], debt_to_income_ratio=[0.05, 0.1, 0.2], purpose=["car","car","car"])
    th = derive_purpose_thresholds(cohort)
    g = assign_grade(0.07, th.thresholds, th.grades)
    @test g in ["A","B","C","D","E","F","G"]
end

