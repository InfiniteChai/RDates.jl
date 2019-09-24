using Test
using RDates
using Dates
using ParserCombinator

struct DummyCalendarManager <: RDates.CalendarManager end

function with_cal_mgr(f::Function, cal_mgr::RDates.CalendarManager)
    global calendar_mgr
    current_cal_mgr = calendar_mgr
    calendar_mgr = cal_mgr
    try
        f()
    finally
        calendar_mgr = current_cal_mgr
    end
end

calendar_mgr = nothing
Base.:+(x::RDates.RDate, y::Date) = RDates.apply(x, y, calendar_mgr)
Base.:+(x::Date, y::RDates.RDate) = RDates.apply(y, x, calendar_mgr)

@testset "rdate calendar adjustments" begin
    cal_mgr = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))
    with_cal_mgr(cal_mgr) do
        @test RDates.CalendarAdj("WEEKEND", rd"1d", RDates.HolidayRoundingNBD()) + Date(2019,4,16) == Date(2019,4,17)
        @test RDates.CalendarAdj("WEEKEND", rd"1d", RDates.HolidayRoundingNBD()) + Date(2019,9,27) == Date(2019,9,30)
        @test RDates.CalendarAdj("WEEKEND", rd"1d", RDates.HolidayRoundingNBD()) + Date(2019,11,29) == Date(2019,12,2)
        @test RDates.CalendarAdj("WEEKEND", rd"1d", RDates.HolidayRoundingNBDSM()) + Date(2019,11,29) == Date(2019,11,29)

        @test rd"1d@WEEKEND[NBD]" == RDates.CalendarAdj("WEEKEND", rd"1d", RDates.HolidayRoundingNBD())
        @test rd"(2w + 3E)@WEEKEND[NBDSM]" == RDates.CalendarAdj("WEEKEND", rd"2w + 3E", RDates.HolidayRoundingNBDSM())
    end
end

@testset "rdate business days" begin
    cal_mgr = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))
    with_cal_mgr(cal_mgr) do
        @test rd"0b@WEEKEND" + Date(2019,9,28) == Date(2019,9,30)
        @test rd"-0b@WEEKEND" + Date(2019,9,28) == Date(2019,9,27)
        @test rd"1b@WEEKEND" + Date(2019,9,28) == Date(2019,9,30)
        @test rd"2b@WEEKEND" + Date(2019,9,28) == Date(2019,10,1)
    end
end

@testset "rdate add ordering" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"1d" + Date(2019,4,16) == Date(2019,4,17)
        @test Date(2019,4,16) + rd"1d" == Date(2019,4,17)
        @test rd"1d+2d" == rd"1d" + rd"2d"
        @test rd"3*1d" == 3 * rd"1d"
    end
end

@testset "codified rdate generation" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test RDates.Day(1) == rd"1d"
        @test RDates.Day(2) + RDates.Week(3) == rd"2d + 3w"
        @test 2 * (RDates.Year(3) + RDates.Month(1)) == rd"2*(3y + 1m)"
        @test RDates.Weekdays(Mon, 3) == rd"3MON"
        @test RDates.DayMonth(23, Feb) == rd"23FEB"
        @test RDates.NthWeekdays(Fri, 1) == rd"1st FRI"
        @test RDates.NthLastWeekdays(Sun, 2) == rd"2nd Last SUN"
    end
end

@testset "different month and year conventions" begin
    with_cal_mgr(DummyCalendarManager()) do
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
    end
end

@testset "rdate whitespace" begin
    @test rd"  1d" == rd"1d"
    @test rd"1d  + 3d" == rd"1d+3d"
    @test rd"--1d" == rd"1d"
end

@testset "relative add days" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"1d" + Date(2019,4,16) == Date(2019,4,17)
        @test rd"1d" + Date(2019,4,30) == Date(2019,5,1)
        @test rd"0d" + Date(2015,3,23) == Date(2015,3,23)
        @test rd"7d" + Date(2017,10,25) == Date(2017,11,1)
        @test rd"-1d" + Date(2014,1,1) == Date(2013,12,31)
    end
end

@testset "relative add weeks" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"1w" + Date(2019,4,16) == Date(2019,4,23)
        @test rd"1w" + Date(2019,4,30) == Date(2019,5,7)
        @test rd"0w" + Date(2015,3,23) == Date(2015,3,23)
        @test rd"7w" + Date(2017,10,25) == Date(2017,12,13)
        @test rd"-1w" + Date(2014,1,1) == Date(2013,12,25)
    end
end

@testset "relative add months" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"1m" + Date(2019,4,16) == Date(2019,5,16)
        @test rd"1m" + Date(2019,4,30) == Date(2019,5,30)
        @test rd"0m" + Date(2015,3,23) == Date(2015,3,23)
        @test rd"12m" + Date(2017,10,25) == Date(2018,10,25)
        @test rd"-1m" + Date(2014,1,1) == Date(2013,12,1)
    end
end

@testset "relative add years" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"1y" + Date(2019,4,16) == Date(2020,4,16)
        @test rd"1y" + Date(2019,4,30) == Date(2020,4,30)
        @test rd"0m" + Date(2015,3,23) == Date(2015,3,23)
        @test rd"12y" + Date(2017,10,25) == Date(2029,10,25)
        @test rd"-1y" + Date(2014,1,1) == Date(2013,1,1)
    end
end

@testset "relative add daymonths" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"12MAR" + Date(2018,3,3) == Date(2018,3,12)
        @test rd"1JAN" + Date(2019,12,31) == Date(2019,1,1)
        @test rd"1JAN" + Date(2020,1,1) == Date(2020,1,1)
    end
end

@testset "relative add easter" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"0E" + Date(2018,3,3) == Date(2018,4,1)
        @test rd"0E" + Date(2018,12,3) == Date(2018,4,1)
        @test rd"1E" + Date(2018,3,3) == Date(2019,4,21)
        @test rd"-1E" + Date(2018,3,3) == Date(2017,4,16)
    end
end

@testset "relative add weekdays" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"1MON" + Date(2017,10,25) == Date(2017,10,30)
        @test rd"10SAT" + Date(2017,10,25) == Date(2017,12,30)
        @test rd"-1WED" + Date(2017,10,25) == Date(2017,10,18)
        @test rd"-10FRI" + Date(2017,10,25) == Date(2017,8,18)
        @test rd"-1TUE" + Date(2017,10,25) == Date(2017,10,24)
    end
end

@testset "bad negations" begin
    @test_throws ErrorException rd"1d" - rd"1st MON"
end

@testset "relative add nth weekdays" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"1st MON" + Date(2017,10,25) == Date(2017,10,2)
        @test rd"2nd FRI" + Date(2017,10,25) == Date(2017,10,13)
        @test rd"4th SAT" + Date(2017,11,25) == Date(2017,11,25)
        @test rd"5th SUN" + Date(2017,12,25) == Date(2017,12,31)
    end
end

@testset "relative add nth last weekdays" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"Last MON" + Date(2017,10,24) == Date(2017,10,30)
        @test rd"2nd Last FRI" + Date(2017,10,24) == Date(2017,10,20)
        @test rd"5th Last SUN" + Date(2017,12,24) == Date(2017,12,3)
    end
end

@testset "bad nth weekdays" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test_throws ArgumentError rd"5th WED" + Date(2017,10,25)
        @test_throws ArgumentError rd"5th MON" + Date(2017,6,1)
    end
end

@testset "relative begin or end of month" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test rd"FDOM" + Date(2017,10,25) == Date(2017,10,1)
        @test rd"LDOM" + Date(2017,10,25) == Date(2017,10,31)
    end
end

@testset "basic addition and multiplication compounds" begin
    with_cal_mgr(DummyCalendarManager()) do
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
        @test 3*rd"1d" + Date(2017,4,14) == Date(2017,4,17)
        @test rd"1d"*3 + Date(2017,4,14) == Date(2017,4,17)
    end
end

@testset "rdate ranges" begin
    with_cal_mgr(DummyCalendarManager()) do
        @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"1d")) == [Date(2017,1,1), Date(2017,1,2), Date(2017,1,3)]
        @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"2d")) == [Date(2017,1,1), Date(2017,1,3)]
        @test collect(range(Date(2017,1,1), Date(2017,1,18), rd"1d+1w")) == [Date(2017,1,1), Date(2017,1,9), Date(2017,1,17)]
        @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"1d", inc_from=false)) == [Date(2017,1,2), Date(2017,1,3)]
        @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"1d", inc_to=false)) == [Date(2017,1,1), Date(2017,1,2)]
        @test collect(range(Date(2017,1,1), Date(2017,1,3), rd"1d", inc_from=false, inc_to=false)) == [Date(2017,1,2)]
    end
end

@testset "rdate parsing methods" begin
    @test rdate("1d") == rd"1d"
    @test rdate("3*2d") == rd"3*2d"
end

@testset "fail to parse bad rdates" begin
    @test_throws ErrorException rdate("1*2")
    @test_throws ParserCombinator.ParserException rdate("1dw")
    @test_throws ParserCombinator.ParserException rdate("+2d")
    @test_throws ParserCombinator.ParserException rdate("2d+")
    @test_throws ParserCombinator.ParserException rdate("d")
end
