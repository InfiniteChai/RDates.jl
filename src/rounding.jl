import Dates

"""
    HolidayRoundingNBD()

Move to the next business day when a date falls on a holiday.

#### Examples
```julia-repl
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(RDates.CalendarAdj("WEEKEND", rd"0d", RDates.HolidayRoundingNBD()), Date(2021,7,10), cal_mgr)
2021-07-12
julia> apply(rd"0d@WEEKEND[NBD]", Date(2021,7,10), cal_mgr)
2021-07-12
```
"""
struct HolidayRoundingNBD <: HolidayRoundingConvention end
function apply(::HolidayRoundingNBD, date::Dates.Date, calendar::Calendar)::Dates.Date
    while is_holiday(calendar, date)
        date += Dates.Day(1)
    end
    date
end
Base.show(io::IO, ::HolidayRoundingNBD) = print(io, "NBD")

"""
    HolidayRoundingPBD()


Move to the previous business day when a date falls on a holiday.

#### Examples
```julia-repl
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(RDates.CalendarAdj("WEEKEND", rd"0d", RDates.HolidayRoundingPBD()), Date(2021,7,10), cal_mgr)
2021-07-09
julia> apply(rd"0d@WEEKEND[PBD]", Date(2021,7,10), cal_mgr)
2021-07-09
```
"""
struct HolidayRoundingPBD <: HolidayRoundingConvention end
function apply(::HolidayRoundingPBD, date::Dates.Date, calendar::Calendar)::Dates.Date
    while is_holiday(calendar, date)
        date -= Dates.Day(1)
    end
    date
end
Base.show(io::IO, ::HolidayRoundingPBD) = print(io, "PBD")

"""
    HolidayRoundingNBDSM()

Move to the next business day when a date falls on a holiday, unless the adjusted
date would be in the next month, then go the previous business date instead.

#### Examples
```julia-repl
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(RDates.CalendarAdj("WEEKEND", rd"0d", RDates.HolidayRoundingNBDSM()), Date(2021,7,10), cal_mgr)
2021-07-12
julia> apply(rd"0d@WEEKEND[NBDSM]", Date(2021,7,10), cal_mgr)
2021-07-12
julia> apply(rd"0d@WEEKEND[NBDSM]", Date(2021,7,31), cal_mgr)
2021-07-30
```
"""
struct HolidayRoundingNBDSM <: HolidayRoundingConvention end
function apply(::HolidayRoundingNBDSM, date::Dates.Date, calendar::Calendar)::Dates.Date
    new_date = date
    while is_holiday(calendar, new_date)
        new_date += Dates.Day(1)
    end

    if Dates.month(new_date) != Dates.month(date)
        new_date = date
        while is_holiday(calendar, new_date)
            new_date -= Dates.Day(1)
        end
    end

    new_date
end
Base.show(io::IO, ::HolidayRoundingNBDSM) = print(io, "NBDSM")


"""
    HolidayRoundingPBDSM()

Move to the previous business day when a date falls on a holiday, unless the adjusted
date would be in the previous month, then go the next business date instead.

#### Examples
```julia-repl
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(RDates.CalendarAdj("WEEKEND", rd"0d", RDates.HolidayRoundingPBDSM()), Date(2021,7,10), cal_mgr)
2021-07-09
julia> apply(rd"0d@WEEKEND[PBDSM]", Date(2021,7,10), cal_mgr)
2021-07-09
julia> apply(rd"0d@WEEKEND[NBDSM]", Date(2021,8,1), cal_mgr)
2021-08-02
```
"""
struct HolidayRoundingPBDSM <: HolidayRoundingConvention end
function apply(::HolidayRoundingPBDSM, date::Dates.Date, calendar::Calendar)::Dates.Date
    new_date = date
    while is_holiday(calendar, new_date)
        new_date -= Dates.Day(1)
    end

    if Dates.month(new_date) != Dates.month(date)
        new_date = date
        while is_holiday(calendar, new_date)
            new_date += Dates.Day(1)
        end
    end

    new_date
end
Base.show(io::IO, ::HolidayRoundingPBDSM) = print(io, "PBDSM")


"""
    HolidayRoundingNR()

No rounding, so just give back the same date even though it's a holiday. Uses
"NR" for short hand.

#### Examples
```julia-repl
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(RDates.CalendarAdj("WEEKEND", rd"0d", RDates.HolidayRoundingNR()), Date(2021,7,10), cal_mgr)
2021-07-10
julia> apply(rd"0d@WEEKEND[NR]", Date(2021,7,10), cal_mgr)
2021-07-10
```
"""
struct HolidayRoundingNR <: HolidayRoundingConvention end
apply(::HolidayRoundingNR, date::Dates.Date, ::Calendar) = date
Base.show(io::IO, ::HolidayRoundingNR) = print(io, "NR")


"""
    HolidayRoundingNearest()

Move to the nearest business day, with the next one taking precedence in a tie.
This is commonly used for U.S. calendars which will adjust Sat to Fri and Sun to Mon
for their fixed date holidays.


#### Examples
```julia-repl
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(RDates.CalendarAdj("WEEKEND", rd"0d", RDates.HolidayRoundingNearest()), Date(2021,7,10), cal_mgr)
2021-07-09
julia> apply(rd"0d@WEEKEND[NEAR]", Date(2021,7,10), cal_mgr)
2021-07-09
julia> apply(rd"0d@WEEKEND[NEAR]", Date(2021,7,11), cal_mgr)
2021-07-12
```
"""
struct HolidayRoundingNearest <: HolidayRoundingConvention end
function apply(::HolidayRoundingNearest, date::Dates.Date, cal::Calendar)
    is_holiday(cal, date) || return date
    count = 0
    result = nothing
    while result === nothing
        up_date = date + Dates.Day(count)
        if !is_holiday(cal, up_date)
            result = up_date
        else
            down_date = date - Dates.Day(count)
            if !is_holiday(cal, down_date)
                result = down_date
            end
        end
        count += 1
    end
    result
end
Base.show(io::IO, ::HolidayRoundingNearest) = print(io, "NEAR")


const HOLIDAY_ROUNDING_MAPPINGS = Dict(
    "NR" => HolidayRoundingNR(),
    "NBD" => HolidayRoundingNBD(),
    "PBD" => HolidayRoundingPBD(),
    "NBDSM" => HolidayRoundingNBDSM(),
    "PBDSM" => HolidayRoundingPBDSM(),
    "NEAR" => HolidayRoundingNearest()
)
