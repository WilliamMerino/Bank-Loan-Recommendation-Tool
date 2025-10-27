using Test
using DataFrames

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using BankLoanRecommendationTool

@testset "dataset validation" begin
    csv_path = joinpath(@__DIR__, "..", "data", "loan_data.csv")
    issues = validate_dataset_file(csv_path)
    if !isempty(issues)
        buf = IOBuffer()
        println(buf, "Dataset validation failed with the following discrepancies:")
        for entry in issues
            println(buf, "Row $(entry.row):")
            for msg in entry.issues
                println(buf, "  - $(msg)")
            end
        end
        error(String(take!(buf)))
    end
    @test isempty(issues)
end

@testset "user row validation" begin
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
    valid_df = DataFrame([valid_row])
    @test isempty(validate_dataset(valid_df))

    invalid_row = (
        id = "2",
        address_state = "NY",
        application_type = "SHARED",
        emp_length = "abc",
        grade = "Z",
        home_ownership = "UNKNOWN",
        issue_date = "2020-13-01",
        last_credit_pull_date = "notadate",
        last_payment_date = "13/40/20",
        loan_status = "Late",
        member_id = "654321",
        purpose = "car",
        sub_grade = "Z9",
        term = 12,
        verification_status = "Nope",
        annual_income = -10_000.0,
        debt_to_income_ratio = 5.5,
        monthly_installment = -100.0,
        int_rate = 1.5,
        loan_amount = -2_000.0,
        total_accounts = -1,
        total_payment = -50.0,
    )
    df_with_invalid = DataFrame([valid_row, invalid_row])
    issues = validate_dataset(df_with_invalid)

    @test length(issues) == 1
    @test issues[1].row == 2
    invalid_messages = issues[1].issues
    @test any(occursin("annual_income", msg) for msg in invalid_messages)
    @test any(occursin("grade must be one of", msg) for msg in invalid_messages)
    @test any(occursin("term should be 36 or 60 months", msg) for msg in invalid_messages)
    @test any(occursin("verification_status", msg) for msg in invalid_messages)
    @test any(occursin("emp_length", msg) for msg in invalid_messages)
end
