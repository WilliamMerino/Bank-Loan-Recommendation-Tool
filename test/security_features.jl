using Test
using DataFrames

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using BankLoanRecommendationTool

const BASE_ROW = (
    id = "1",
    address_state = "CA",
    application_type = "INDIVIDUAL",
    emp_length = "10 years",
    grade = "A",
    home_ownership = "MORTGAGE",
    issue_date = "1/1/20",
    last_credit_pull_date = "1/1/21",
    last_payment_date = "1/1/21",
    loan_status = "Fully Paid",
    member_id = "123456",
    purpose = "car",
    sub_grade = "A1",
    term = 36,
    verification_status = "Verified",
    annual_income = 65_000.0,
    debt_to_income_ratio = 0.35,
    monthly_installment = 320.0,
    int_rate = 0.08,
    loan_amount = 12_000.0,
    total_accounts = 14,
    total_payment = 13_500.0,
)

@testset "purpose sanitization" begin
    safe_df = DataFrame([BASE_ROW])
    @test isempty(validate_dataset(safe_df))

    unsafe_row = Base.merge(BASE_ROW, (purpose = "<script>alert(1)</script>",))
    df = DataFrame([unsafe_row])
    issues = validate_dataset(df)
    @test length(issues) == 1
    @test any(occursin("unsafe characters", msg) for msg in issues[1].issues)
end

@testset "mixed dataset sanitization" begin
    acceptable = Base.merge(BASE_ROW, (id = "3", member_id = "789000", purpose = "home improvement",))
    dangerous = Base.merge(BASE_ROW, (id = "4", member_id = "789001", purpose = "educational<script>",))
    df = DataFrame([BASE_ROW, acceptable, dangerous])
    issues = validate_dataset(df)
    @test length(issues) == 1
    @test issues[1].row == 3
    @test any(occursin("unsafe characters", msg) for msg in issues[1].issues)
end
