using Test
using RDates
using Dates
using ParserCombinator

cal_mgr = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))

@testset "RDates" begin
    @testset "Rounding Conventions" begin
        @test apply(rd"0d@WEEKEND[NBD]", Date(2021,7,10), cal_mgr) == Date(2021,7,12)
        @test apply(rd"0d@WEEKEND[NBD]", Date(2021,7,11), cal_mgr) == Date(2021,7,12)
        @test apply(rd"0d@WEEKEND[NBDSM]", Date(2021,7,10), cal_mgr) == Date(2021,7,12)
        @test apply(rd"0d@WEEKEND[NBDSM]", Date(2021,7,11), cal_mgr) == Date(2021,7,12)
        @test apply(rd"0d@WEEKEND[PBD]", Date(2021,7,10), cal_mgr) == Date(2021,7,9)
        @test apply(rd"0d@WEEKEND[PBD]", Date(2021,7,11), cal_mgr) == Date(2021,7,9)
        @test apply(rd"0d@WEEKEND[PBDSM]", Date(2021,7,10), cal_mgr) == Date(2021,7,9)
        @test apply(rd"0d@WEEKEND[PBDSM]", Date(2021,7,11), cal_mgr) == Date(2021,7,9)
        @test apply(rd"0d@WEEKEND[NR]", Date(2021,7,10), cal_mgr) == Date(2021,7,10)
        @test apply(rd"0d@WEEKEND[NR]", Date(2021,7,11), cal_mgr) == Date(2021,7,11)
        @test apply(rd"0d@WEEKEND[NEAR]", Date(2021,7,10), cal_mgr) == Date(2021,7,9)
        @test apply(rd"0d@WEEKEND[NEAR]", Date(2021,7,11), cal_mgr) == Date(2021,7,12)
        # same month special casing
        @test apply(rd"0d@WEEKEND[NBDSM]", Date(2021,7,31), cal_mgr) == Date(2021,7,30)
        @test apply(rd"0d@WEEKEND[NBDSM]", Date(2021,8,1), cal_mgr) == Date(2021,8,2)
        @test apply(rd"0d@WEEKEND[PBDSM]", Date(2021,7,31), cal_mgr) == Date(2021,7,30)
        @test apply(rd"0d@WEEKEND[PBDSM]", Date(2021,8,1), cal_mgr) == Date(2021,8,2)

    end
end

@testset "rdate calendar adjustments" begin
    cal_mgr = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))
    @test apply(RDates.CalendarAdj(["WEEKEND"], rd"1d", RDates.HolidayRoundingNBD()), Date(2019,4,16), cal_mgr) == Date(2019,4,17)
    @test apply(RDates.CalendarAdj(["WEEKEND"], rd"1d", RDates.HolidayRoundingNBD()), Date(2019,9,27), cal_mgr) == Date(2019,9,30)
    @test apply(RDates.CalendarAdj(["WEEKEND"], rd"1d", RDates.HolidayRoundingNBD()), Date(2019,11,29), cal_mgr) == Date(2019,12,2)
    @test apply(RDates.CalendarAdj(["WEEKEND"], rd"1d", RDates.HolidayRoundingNBDSM()), Date(2019,11,29), cal_mgr) == Date(2019,11,29)
end

@testset "rdate business days" begin
    cal_mgr = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))
    @test apply(rd"0b@WEEKEND", Date(2019,9,28), cal_mgr) == Date(2019,9,30)
    @test apply(rd"-0b@WEEKEND", Date(2019,9,28), cal_mgr) == Date(2019,9,27)
    @test apply(rd"1b@WEEKEND", Date(2019,9,28), cal_mgr) == Date(2019,10,1)
    @test apply(rd"-1b@WEEKEND", Date(2019,9,28), cal_mgr) == Date(2019,9,26)
    @test apply(rd"2b@WEEKEND", Date(2019,9,28), cal_mgr) == Date(2019,10,2)
end

@testset "rdate add ordering" begin
    @test rd"1d" + Date(2019,4,16) == Date(2019,4,17)
    @test Date(2019,4,16) + rd"1d" == Date(2019,4,17)
    @test rd"1d+2d" == rd"1d" + rd"2d"
    @test rd"3*1d" == RDates.multiply_roll(rd"1d",3)
end

@testset "different month and year conventions" begin
    @test RDates.Year(1) + Date(2016,2,29) == Date(2017,2,28)
    @test Dates.Year(1) + Date(2016,2,29) == Date(2017,2,28)
    @test rd"1y" + Date(2016,2,29) == Date(2017,2,28)
    @test RDates.Year(1, RDates.InvalidDayLDOM(), RDates.MonthIncrementPDOM()) + Date(2016,2,29) == Date(2017,2,28)
    @test rd"1y[LDOM;PDOM]" + Date(2016,2,29) == Date(2017,2,28)
    @test RDates.Year(1, RDates.InvalidDayFDONM(), RDates.MonthIncrementPDOM()) + Date(2016,2,29) == Date(2017,3,1)
    @test rd"1y[FDONM;PDOM]" + Date(2016,2,29) == Date(2017,3,1)

    @test RDates.Month(1) + Date(2019,1,31) == Date(2019,2,28)
    @test Dates.Month(1) + Date(2019,1,31) == Date(2019,2,28)
    @test rd"1m" + Date(2019,1,31) == Date(2019,2,28)
    @test RDates.Month(1, RDates.InvalidDayNDONM(), RDates.MonthIncrementPDOM()) + Date(2019,1,31) == Date(2019,3,3)
    @test rd"1m[NDONM;PDOM]" + Date(2019,1,31) == Date(2019,3,3)
    @test RDates.Month(1, RDates.InvalidDayFDONM(), RDates.MonthIncrementPDOM()) + Date(2019,1,31) == Date(2019,3,1)
    @test rd"1m[FDONM;PDOM]" + Date(2019,1,31) == Date(2019,3,1)
    @test RDates.Month(1, RDates.InvalidDayNDONM(), RDates.MonthIncrementPDOMEOM()) + Date(2019,1,31) == Date(2019,2,28)
    @test rd"1m[NDONM;PDOMEOM]" + Date(2019,1,31) == Date(2019,2,28)
    @test RDates.Month(1, RDates.InvalidDayNDONM(), RDates.MonthIncrementPDOMEOM()) + Date(2019,1,30) == Date(2019,3,2)
    @test rd"1m[NDONM;PDOMEOM]" + Date(2019,1,30) == Date(2019,3,2)

    # PDOMEOM can also support calendars to work off the last business day of the month
    cal_mgr = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))
    @test apply(rd"3m[LDOM;PDOMEOM@WEEKEND]", Date(2019,8,30), cal_mgr) == Date(2019,11,29)
end

@testset "rdate whitespace" begin
    @test rd"  1d" == rd"1d"
    @test rd"1d  + 3d" == rd"1d+3d"
    @test rd"--1d" == rd"1d"
end

@testset "relative add days" begin
    @test rd"1d" + Date(2019,4,16) == Date(2019,4,17)
    @test rd"1d" + Date(2019,4,30) == Date(2019,5,1)
    @test rd"0d" + Date(2015,3,23) == Date(2015,3,23)
    @test rd"7d" + Date(2017,10,25) == Date(2017,11,1)
    @test rd"-1d" + Date(2014,1,1) == Date(2013,12,31)
end

@testset "relative add weeks" begin
    @test rd"1w" + Date(2019,4,16) == Date(2019,4,23)
    @test rd"1w" + Date(2019,4,30) == Date(2019,5,7)
    @test rd"0w" + Date(2015,3,23) == Date(2015,3,23)
    @test rd"7w" + Date(2017,10,25) == Date(2017,12,13)
    @test rd"-1w" + Date(2014,1,1) == Date(2013,12,25)
end

@testset "relative add months" begin
    @test rd"1m" + Date(2019,4,16) == Date(2019,5,16)
    @test rd"1m" + Date(2019,4,30) == Date(2019,5,30)
    @test rd"0m" + Date(2015,3,23) == Date(2015,3,23)
    @test rd"12m" + Date(2017,10,25) == Date(2018,10,25)
    @test rd"-1m" + Date(2014,1,1) == Date(2013,12,1)
end

@testset "relative add years" begin
    @test rd"1y" + Date(2019,4,16) == Date(2020,4,16)
    @test rd"1y" + Date(2019,4,30) == Date(2020,4,30)
    @test rd"0m" + Date(2015,3,23) == Date(2015,3,23)
    @test rd"12y" + Date(2017,10,25) == Date(2029,10,25)
    @test rd"-1y" + Date(2014,1,1) == Date(2013,1,1)
end

@testset "relative add daymonths" begin
    @test rd"12MAR" + Date(2018,3,3) == Date(2018,3,12)
    @test rd"1JAN" + Date(2019,12,31) == Date(2019,1,1)
    @test rd"1JAN" + Date(2020,1,1) == Date(2020,1,1)
end

@testset "relative add easter" begin
    @test rd"0E" + Date(2018,3,3) == Date(2018,4,1)
    @test rd"0E" + Date(2018,12,3) == Date(2018,4,1)
    @test rd"1E" + Date(2018,3,3) == Date(2019,4,21)
    @test rd"-1E" + Date(2018,3,3) == Date(2017,4,16)
end

@testset "relative add weekdays" begin
    @test rd"1MON" + Date(2017,10,25) == Date(2017,10,30)
    @test rd"10SAT" + Date(2017,10,25) == Date(2017,12,30)
    @test rd"-1WED" + Date(2017,10,25) == Date(2017,10,18)
    @test rd"-10FRI" + Date(2017,10,25) == Date(2017,8,18)
    @test rd"-1TUE" + Date(2017,10,25) == Date(2017,10,24)
end

@testset "dates as rdates" begin
    @test rd"1JAN2019" + Date(2017,10,25) == Date(2019,1,1)
    @test RDates.Date(Date(2019,1,1)) + Date(2017,10,25) == Date(2019,1,1)
end

@testset "negations for 'non-supported' rdates" begin
    @test rd"1d" - rd"1st MON" == rd"1d" + rd"1st MON"
end

@testset "relative add nth weekdays" begin
    @test rd"1st MON" + Date(2017,10,25) == Date(2017,10,2)
    @test rd"2nd FRI" + Date(2017,10,25) == Date(2017,10,13)
    @test rd"4th SAT" + Date(2017,11,25) == Date(2017,11,25)
    @test rd"5th SUN" + Date(2017,12,25) == Date(2017,12,31)
end

@testset "relative add nth last weekdays" begin
    @test rd"Last MON" + Date(2017,10,24) == Date(2017,10,30)
    @test rd"2nd Last FRI" + Date(2017,10,24) == Date(2017,10,20)
    @test rd"5th Last SUN" + Date(2017,12,24) == Date(2017,12,3)
end

@testset "bad nth weekdays" begin
    @test_throws ArgumentError rd"5th WED" + Date(2017,10,25)
    @test_throws ArgumentError rd"5th MON" + Date(2017,6,1)
end

@testset "relative begin or end of month" begin
    @test rd"FDOM" + Date(2017,10,25) == Date(2017,10,1)
    @test rd"LDOM" + Date(2017,10,25) == Date(2017,10,31)

    # FDOM and LDOM can support calendars as well.
    cal_mgr = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))
    @test apply(rd"FDOM@WEEKEND", Date(2019,9,25), cal_mgr) == Date(2019,9,2)
    @test apply(rd"LDOM@WEEKEND", Date(2019,8,25), cal_mgr) == Date(2019,8,30)
end

@testset "basic addition and multiplication compounds" begin
    @test rd"1d+1d" + Date(2017,10,26) == Date(2017,10,28)
    @test rd"2*1d" + Date(2017,10,26) == Date(2017,10,28)
    @test rd"1d+1d+1d+1d" + Date(2017,10,26) == Date(2017,10,30)
    @test rd"4*1d" + Date(2017,10,26) == Date(2017,10,30)
    @test rd"2*2d" + Date(2017,10,26) == Date(2017,10,30)
    @test rd"1d-1d+1d-1d" + Date(2017,10,26) == Date(2017,10,26)
    @test rd"2*3d+1d" + Date(2019,4,16) == Date(2019,4,23)
    @test rd"2*(3d+1d)" + Date(2019,4,16) == Date(2019,4,24)
    @test rd"2d-1E" + Date(2019,4,16) == Date(2018,4,1)
    @test rd"1d" - rd"2*1d" + Date(2019,5,1) == Date(2019,4,30)
    @test RDates.multiply_no_roll(rd"1d", 3) + Date(2017,4,14) == Date(2017,4,17)
end

@testset "roll versus no roll addition" begin
    # If we apply each 1m addition individually, then invalid days in Feb kicks in.
    @test rd"1m+1m" + Date(2019,1,31) == Date(2019,3,28)
    @test rd"2*roll(1m)" + Date(2019,1,31) == Date(2019,3,28)
    # Normal multiplication will embed this in the period instead.
    @test rd"2m" + Date(2019,1,31) == Date(2019,3,31)
    @test rd"2*1m" + Date(2019,1,31) == Date(2019,3,31)
end

@testset "rdate ranges" begin
    @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"1d")) == [Date(2017,1,1), Date(2017,1,2), Date(2017,1,3)]
    @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"2d")) == [Date(2017,1,1), Date(2017,1,3)]
    @test collect(range(Date(2017,1,1), Date(2017,1,18), rd"1d+1w")) == [Date(2017,1,1), Date(2017,1,9), Date(2017,1,17)]
    @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"1d", inc_from=false)) == [Date(2017,1,2), Date(2017,1,3)]
    @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"1d", inc_to=false)) == [Date(2017,1,1), Date(2017,1,2)]
    @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"1d", inc_from=false, inc_to=false)) == [Date(2017,1,2)]
    @test collect(range(Date(2017,1,1), Date(2018,1,1), rd"1DEC2017 + 3m + 3rd WED")) == [Date(2017,3,15), Date(2017,6,21), Date(2017,9,20), Date(2017,12,20)]
end

@testset "rdate parsing methods" begin
    @test rdate("1d") == rd"1d"
    @test rdate("3*2d") == rd"3*2d"
    @test rd"3*2d" == 3*rd"2d"
end

@testset "fail to parse bad rdates" begin
    @test_throws ParserCombinator.ParserException rdate("1*2")
    @test_throws ParserCombinator.ParserException rdate("1dw")
    @test_throws ParserCombinator.ParserException rdate("+2d")
    @test_throws ParserCombinator.ParserException rdate("2d+")
    @test_throws ParserCombinator.ParserException rdate("d")
end

@testset "string form" begin
    @test string(rd"1d") == "1d"
    @test string(rd"3d + 2w") == "17d"
    @test string(rd"2*(1m + 1y)") == "2m[LDOM;PDOM]+2y[LDOM;PDOM]"
    @test string(rd"2*roll(1m)") == "2*roll(1m[LDOM;PDOM])"
    @test string(rd"1m[LDOM;PDOMEOM@A]@B[NBD]") == "(1m[LDOM;PDOMEOM@A])@B[NBD]"
    @test string(rd"(1m+2d)@A[PBD]") == "(1m[LDOM;PDOM]+2d)@A[PBD]"
end
