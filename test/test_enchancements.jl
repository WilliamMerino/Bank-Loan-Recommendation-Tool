using Test
using DataFrames

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using BankLoanRecommendationTool

@testset "analytics helpers" begin
    df = DataFrame(
        grade = ["A", "B", "A", missing],
        purpose = ["car", "car", "house", "car"],
        loan_amount = [10_000.0, 8_000.0, 12_000.0, 9_000.0],
        debt_to_income_ratio = [0.25, 0.4, 0.2, missing],
        int_rate = [0.07, 0.09, 0.05, 0.08],
    )

    dist = grade_distribution(df)
    @test dist.counts == Dict("A" => 2, "B" => 1)
    @test dist.missing == 1

    summary = purpose_summary(df)
    @test nrow(summary) == 2
    car_row = summary[summary.purpose .== "car", :]
    @test car_row.count[1] == 3
    @test isapprox(car_row.avg_loan_amount[1], 9_000.0; atol=1e-6)
    @test isapprox(car_row.avg_debt_to_income_ratio[1], 0.325; atol=1e-6)
    @test isapprox(car_row.avg_int_rate[1], 8.0; atol=1e-6)
end

@testset "quality metrics" begin
    valid_row = (
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
    invalid_row = (
        id = "2",
        address_state = "NY",
        application_type = "JOINT",
        emp_length = missing,
        grade = "H",
        home_ownership = "RENT",
        issue_date = "18/18/20",
        last_credit_pull_date = missing,
        last_payment_date = missing,
        loan_status = "Late",
        member_id = "111111",
        purpose = missing,
        sub_grade = "H9",
        term = 12,
        verification_status = "Not Verified",
        annual_income = -10_000.0,
        debt_to_income_ratio = 4.0,
        monthly_installment = -1.0,
        int_rate = 1.2,
        loan_amount = -5_000.0,
        total_accounts = -2,
        total_payment = -100.0,
    )
    df = DataFrame([valid_row, invalid_row])
    metrics = compute_quality_metrics(df)
    @test metrics.row_count == 2
    @test metrics.missing_counts[:emp_length] == 1
    @test :purpose in metrics.missing_columns
    @test metrics.validation_issues > 0
    @test metrics.affected_rows == 1
    @test metrics.issue_rate > 0
end

@testset "audit helpers" begin
    issues = [
        (row=2, issues=["grade must be A-G", "term should be 36 or 60"]),
        (row=5, issues=["annual_income must be > 0"]),
    ]
    report = format_validation_report(issues; max_rows=1)
    @test occursin("Row 2", report)
    @test occursin("… and 1 more rows", report)

    mktemp() do path, io
        close(io) # we only need the path
        save_validation_report(path, issues; include_timestamp=false)
        content = read(path, String)
        @test occursin("Validation issues", content)
        save_validation_report(path, issues; include_timestamp=false, append=true, max_rows=1)
        appended = read(path, String)
        row_lines = count(line -> occursin("Row 2", line), split(appended, '\n'))
        @test row_lines >= 2
    end
end
