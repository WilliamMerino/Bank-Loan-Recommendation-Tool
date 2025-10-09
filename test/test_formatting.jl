using Test
using BankLoanRecommendationTool

@testset "formatting" begin
    @test format_number_with_commas(1234.5; digits=2) == "1,234.50"
    @test format_currency(1000) == "\$1,000.00"
end

