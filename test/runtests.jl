using Test
using RDates
using Dates

@testset "basic relative dates" begin
    @test rd"1d" + Date(2019,4,16) == Date(2019,4,17)
    @test rd"1d" + Date(2019,4,30) == Date(2019,5,1)
end
