import Dates
using AutoHashEquals

const WEEKDAYS = Dict(map(reverse,enumerate(map(Symbol ∘ uppercase, Dates.ENGLISH.days_of_week_abbr))))
const NTH_PERIODS = ["1st", "2nd", "3rd", "4th", "5th"]
const NTH_LAST_PERIODS = ["Last", "2nd Last", "3rd Last", "4th Last", "5th Last"]
const PERIODS = merge(Dict(map(reverse,enumerate(NTH_PERIODS))), Dict(map(reverse,enumerate(NTH_LAST_PERIODS))))
const MONTHS = Dict(zip(map(Symbol ∘ uppercase, Dates.ENGLISH.months_abbr),range(1,stop=12)))

"""
    FDOM()
    FDOM(calendars)

Calculate the first day of the month. Optionally can also take calendar names to determine
the first business day of the month.

### Examples
```julia-repl
julia> RDates.FDOM() + Date(2019,1,13)
2019-01-01
julia> rd"FDOM" + Date(2019,1,13)
2019-01-01
julia> cals = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))
julia> apply(RDates.FDOM("WEEKEND"), Date(2017,1,13), cals)
2017-01-02
julia> apply(rd"FDOM@WEEKEND", Date(2017,1,13), cals)
2017-01-02
```
"""
struct FDOM <: RDate
    FDOM() = new()
    FDOM(calendars::Nothing) = new()
    FDOM(calendars) = CalendarAdj(calendars, new(), HolidayRoundingNBD())
end

apply(::FDOM, d::Dates.Date, ::CalendarManager) = Dates.firstdayofmonth(d)
multiply(x::FDOM, ::Integer) = x
Base.:-(x::FDOM) = x

Base.show(io::IO, ::FDOM) = print(io, "FDOM")
register_grammar!(E"FDOM" > FDOM)
register_grammar!(E"FDOM@" + PCalendarNames() > calendar_name -> FDOM(map(String, split(calendar_name, "|"))))

"""
    LDOM()
    LDOM(calendars)

Calculate the last day of the month. Optionally can also take calendar names to determine
the last business day of the month.

### Examples
```julia-repl
julia> RDates.LDOM() + Date(2019,1,13)
2019-01-31
julia> rd"LDOM" + Date(2019,1,13)
2019-01-31
julia> cals = RDates.SimpleCalendarManager(Dict("WEEKEND" => RDates.WeekendCalendar()))
julia> apply(RDates.LDOM("WEEKEND"), Date(2021,1,13), cals)
2021-01-29
julia> apply(rd"LDOM@WEEKEND", Date(2021,1,13), cals)
2021-01-29
```
"""
struct LDOM <: RDate
    LDOM() = new()
    LDOM(calendars::Nothing) = new()
    LDOM(calendars) = CalendarAdj(calendars, new(), HolidayRoundingPBD())
end

apply(::LDOM, d::Dates.Date, ::CalendarManager) = Dates.lastdayofmonth(d)
multiply(x::LDOM, ::Integer) = x
Base.:-(x::LDOM) = x

Base.show(io::IO, ::LDOM) = print(io, "LDOM")
register_grammar!(E"LDOM" > LDOM)
register_grammar!(E"LDOM@" + PCalendarNames() > calendar_name -> LDOM(map(String, split(calendar_name, "|"))))

"""
    Easter(yearδ::Int64)

A date that is well known from hunting eggs and pictures of bunnies, it's a rather
tricky calculation to perform. We provide a simple method to allow you to get the
Easter for the given year (plus some delta).

!!! note
    `0E` will get the Easter of the current year, so it could be before or
    after the date you've provided.

### Examples
```julia-repl
julia> RDates.Easter(0) + Date(2019,1,1)
2019-04-21
julia> rd"0E" + Date(2019,1,1)
2019-04-21
julia> RDates.Easter(0) + Date(2019,8,1)
2019-04-21
julia> RDates.Easter(10) + Date(2019,8,1)
2029-04-01
```
"""
struct Easter <: RDate
    yearδ::Int64
end

function apply(rdate::Easter, date::Dates.Date, cal_mgr::CalendarManager)
    y = Dates.year(date) + rdate.yearδ
    a = rem(y, 19)
    b = div(y, 100)
    c = rem(y, 100)
    d = div(b, 4)
    e = rem(b, 4)
    f = div(b + 8, 25)
    g = div(b - f + 1, 3)
    h = rem(19*a + b - d - g + 15, 30)
    i = div(c, 4)
    k = rem(c, 4)
    l = rem(32 + 2*e + 2*i - h - k, 7)
    m = div(a + 11*h + 22*l, 451)
    n = div(h + l - 7*m + 114, 31)
    p = rem(h + l - 7*m + 114, 31)
    return Dates.Date(y, n, p + 1)
end

multiply(x::Easter, count::Integer) = Easter(x.yearδ*count)
Base.:-(rdate::Easter) = Easter(-rdate.yearδ)
Base.show(io::IO, rdate::Easter) = print(io, "$(rdate.yearδ)E")
register_grammar!(PInt64() + E"E" > Easter)

"""
    Day(days::Int64)

Provides us with the ability to add or subtract days from a date. This is
equivalent to the `Dates.Day` struct.

### Examples
```julia-repl
julia> RDates.Day(3) + Date(2019,1,1)
2019-01-04
julia> rd"3d" + Date(2019,1,1)
2019-01-04
julia> RDates.Day(-2) + Date(2019,1,1)
2018-12-30
```
"""
struct Day <: RDate
    days::Int64
end

apply(x::Day, y::Dates.Date, cal_mgr::CalendarManager) = y + Dates.Day(x.days)
multiply(x::Day, count::Integer) = Day(x.days*count)
Base.:-(x::Day) = Day(-x.days)
Base.:+(x::Day, y::Day) = Day(x.days + y.days)

Base.show(io::IO, rdate::Day) = print(io, "$(rdate.days)d")
register_grammar!(PInt64() + E"d" > Day)

"""
    Week(weeks::Int64)

Provides us with the ability to add or subtract weeks from a date. This is
equivalent to the `Dates.Week` struct.

### Examples
```julia-repl
julia> RDates.Week(3) + Date(2019,1,1)
2019-01-22
julia> rd"3w" + Date(2019,1,1)
2019-01-22
julia> RDates.Week(-2) + Date(2019,1,1)
2018-12-18
```
"""
struct Week <: RDate
    weeks::Int64
end

apply(x::Week, y::Dates.Date, cal_mgr::CalendarManager) = y + Dates.Week(x.weeks)
multiply(x::Week, count::Integer) = Week(x.weeks*count)
Base.:-(x::Week) = Week(-x.weeks)
Base.:+(x::Week, y::Week) = Week(x.weeks + y.weeks)
Base.:+(x::Day, y::Week) = Day(x.days + 7*y.weeks)
Base.:+(x::Week, y::Day) = Day(7*x.weeks + y.days)

Base.show(io::IO, rdate::Week) = print(io, "$(rdate.weeks)w")
register_grammar!(PInt64() + E"w" > Week)

"""
    Month(months::Int64)
    Month(months::Int64, idc::InvalidDayConvention, mic::MonthIncrementConvention)

Provides us with the ability to move a specified number of months, with conventions
to handle how we should increment and what to do if we fall on an invalid day.

### Examples
```julia-repl
julia> RDates.Month(1) + Date(2019,1,31)
2019-02-28
julia> rd"1m" + Date(2019,1,31)
2019-02-28
julia> RDates.Month(1, RDates.InvalidDayFDONM(), RDates.MonthIncrementPDOM()) + Date(2019,1,31)
2019-03-01
julia> rd"1m[FDONM;PDOM]" + Date(2019,1,31)
2019-03-01
julia> RDates.Month(1, RDates.InvalidDayNDONM(), RDates.MonthIncrementPDOM()) + Date(2019,1,31)
2019-03-03
julia> rd"1m[NDONM;PDOM]" + Date(2019,1,31)
2019-03-03
julia> RDates.Month(1, RDates.InvalidDayNDONM(), RDates.MonthIncrementPDOMEOM()) + Date(2019,1,31)
2019-02-28
julia> rd"1m[NDONM;PDOMEOM]" + Date(2019,1,31)
2019-02-28
julia> RDates.Month(-1, RDates.InvalidDayNDONM(), RDates.MonthIncrementPDOMEOM()) + Date(2019,2,28)
2019-01-31
julia> rd"-1m[NDONM;PDOMEOM]" + Date(2019,2,28)
2019-01-31
```
"""
struct Month <: RDate
    months::Int64
    idc::InvalidDayConvention
    mic::MonthIncrementConvention

    Month(months::Int64) = new(months, InvalidDayLDOM(), MonthIncrementPDOM())
    Month(months::Int64, idc::InvalidDayConvention, mic::MonthIncrementConvention) = new(months, idc, mic)
end

function apply(rdate::Month, date::Dates.Date, cal_mgr::CalendarManager)
    y, m = Dates.yearmonth(date)
    ny = Dates.yearwrap(y, m, rdate.months)
    nm = Dates.monthwrap(m, rdate.months)
    ay, am, ad = adjust(rdate.mic, date, nm, ny, cal_mgr)
    ld = Dates.daysinmonth(ay, am)
    return ad <= ld ? Dates.Date(ay, am, ad) : adjust(rdate.idc, ad, am, ay)
end
multiply(x::Month, count::Integer) = Month(x.months*count, x.idc, x.mic)
Base.:-(x::Month) = Month(-x.months)

Base.show(io::IO, rdate::Month) = (print(io, "$(rdate.months)m["), show(io, rdate.idc), print(io, ";"), show(io, rdate.mic), print(io,"]"))
register_grammar!(PInt64() + E"m" > Month)
register_grammar!(PInt64() + E"m[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";" + Alt(map(Pattern, collect(keys(MONTH_INCREMENT_MAPPINGS)))...) + E"]" > (d,idc,mic) -> Month(d, INVALID_DAY_MAPPINGS[idc], MONTH_INCREMENT_MAPPINGS[mic]))
# We also have the more complex PDOMEOM month increment which we handle separately.
register_grammar!(PInt64() + E"m[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";PDOMEOM@" + PCalendarNames() + E"]" > (d,idc,calendar_name) -> Month(d, INVALID_DAY_MAPPINGS[idc], MonthIncrementPDOMEOM(map(String, split(calendar_name, "|")))))

"""
    Year(years::Int64)
    Year(years::Int64, idc::InvalidDayConvention, mic::MonthIncrementConvention)

Provides us with the ability to move a specified number of months, with conventions
to handle how we should increment and what to do if we fall on an invalid day.

!!! note
    While these conventions are necessary, it's only around the handling of leap years
    and when we're on the last day of the February that it actually matters.

### Examples
```julia-repl
julia> RDates.Year(1) + Date(2019,2,28)
2020-02-28
julia> rd"1y" + Date(2019,2,28)
2020-02-28
julia> RDates.Year(1, RDates.InvalidDayFDONM(), RDates.MonthIncrementPDOMEOM()) + Date(2019,2,28)
2020-02-29
julia> rd"1y[FDONM;PDOMEOM]" + Date(2019,2,28)
2020-02-29
julia> RDates.Year(1, RDates.InvalidDayLDOM(), RDates.MonthIncrementPDOM()) + Date(2020,2,29)
2021-02-28
julia> rd"1y[LDOM;PDOM]" + Date(2020,2,29)
2021-02-28
julia> RDates.Year(1, RDates.InvalidDayFDONM(), RDates.MonthIncrementPDOM()) + Date(2020,2,29)
2021-03-01
julia> rd"1y[FDONM;PDOM]" + Date(2020,2,29)
2021-03-01
```
"""
struct Year <: RDate
    years::Int64
    idc::InvalidDayConvention
    mic::MonthIncrementConvention

    Year(years::Int64) = new(years, InvalidDayLDOM(), MonthIncrementPDOM())
    Year(years::Int64, idc::InvalidDayConvention, mic::MonthIncrementConvention) = new(years, idc, mic)
end

function apply(rdate::Year, date::Dates.Date, cal_mgr::CalendarManager)
    oy, m = Dates.yearmonth(date)
    ny = oy + rdate.years
    (ay, am, ad) = adjust(rdate.mic, date, m, ny, cal_mgr)
    ld = Dates.daysinmonth(ay, am)
    return ad <= ld ? Dates.Date(ay, am, ad) : adjust(rdate.idc, ad, am, ay)
end
multiply(x::Year, count::Integer) = Year(x.years*count, x.idc, x.mic)
Base.:-(x::Year) = Year(-x.years)

Base.show(io::IO, rdate::Year) = (print(io, "$(rdate.years)y["), show(io, rdate.idc), print(io, ";"), show(io, rdate.mic), print(io,"]"))
register_grammar!(PInt64() + E"y" > Year)
register_grammar!(PInt64() + E"y[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";" + Alt(map(Pattern, collect(keys(MONTH_INCREMENT_MAPPINGS)))...) + E"]" > (d,idc,mic) -> Year(d, INVALID_DAY_MAPPINGS[idc], MONTH_INCREMENT_MAPPINGS[mic]))
# We also have the more complex PDOMEOM month increment which we handle separately.
register_grammar!(PInt64() + E"y[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";PDOMEOM@" + PCalendarNames() + E"]" > (d,idc,calendar_name) -> Year(d, INVALID_DAY_MAPPINGS[idc], MonthIncrementPDOMEOM(map(String, split(calendar_name, "|")))))

"""
    DayMonth(day::Int64, month::Int64)
    DayMonth(day::Int64, month::Symbol)

Provides us with the ability to move to a specific day and month in the provided
year.
!!! note
    `1MAR` will get the 1st of March of the current year, so it could be before
    or after the date you've provided.

### Examples
```julia-repl
julia> RDates.DayMonth(23, 10) + Date(2019,1,1)
2019-10-23
julia> RDates.DayMonth(23, :OCT) + Date(2019,1,1)
2019-10-23
julia> rd"23OCT" + Date(2019,1,1)
2019-10-23
```
"""
struct DayMonth <: RDate
    day::Int64
    month::Int64

    DayMonth(day::Int64, month::Int64) = new(day, month)
    DayMonth(day::Int64, month::Symbol) = new(day, RDates.MONTHS[month])
end

apply(rdate::DayMonth, date::Dates.Date, cal_mgr::CalendarManager) = Dates.Date(Dates.year(date), rdate.month, rdate.day)
multiply(x::DayMonth, ::Integer) = x
Base.:-(x::DayMonth) = x

Base.show(io::IO, rdate::DayMonth) = print(io, "$(rdate.day)$(uppercase(Dates.ENGLISH.months_abbr[rdate.month]))")
register_grammar!(PPosInt64() + month_short > (d,m) -> DayMonth(d,MONTHS[Symbol(m)]))


"""
    Date(date::Dates.Date)
    Date(year::Int64, month::Int64, day::Int64)

Provides us with the ability to move to a specific date, irrespective of the date
passed in. This is primarily used when you want to provide a pivot point for ranges
which doesn't relate to the start or end.

### Examples
```julia-repl
julia> RDates.Date(Dates.Date(2017,10,23)) + Date(2019,1,1)
2017-10-23
julia> RDates.Date(2017,10,23) + Date(2019,1,1)
2017-10-23
julia> rd"23OCT2017" + Date(2019,1,1)
2017-10-23
```
"""
struct Date <: RDate
    date::Dates.Date

    Date(date::Dates.Date) = new(date)
    Date(y::Int64, m::Int64, d::Int64) = new(Dates.Date(y, m, d))
end

multiply(x::Date, ::Integer) = x
Base.:-(x::Date) = x

apply(rdate::Date, date::Dates.Date, cal_mgr::CalendarManager) = rdate.date
Base.show(io::IO, rdate::Date) = print(io, "$(Dates.day(rdate.date))$(uppercase(Dates.ENGLISH.months_abbr[Dates.month(rdate.date)]))$(Dates.year(rdate.date))")
register_grammar!(PPosInt64() + month_short + PPosInt64() > (d,m,y) -> Date(Dates.Date(y, MONTHS[Symbol(m)], d)))

"""
    NthWeekdays(dayofweek::Int64, period::Int64)
    NthWeekdays(dayofweek::Symbol, period::Int64)

Move to the nth weekday in the given month and year. This is commonly used for holiday
calendars, such as [Thanksgiving](https://en.wikipedia.org/wiki/Thanksgiving) which in
the U.S. falls on the 4th Thursday in November.

!!! note
    It's possible that a given period (such as the 5th weekday) may exist for only
    a subsection of dates. While it's a valid RDate it may not produce valid results
    when applied (and will throw an exception)

### Examples
```julia-repl
julia> RDates.NthWeekdays(:MON, 2) + Date(2019,1,1)
2019-01-14
julia> RDates.NthWeekdays(1, 2) + Date(2019,1,1)
2019-01-14
julia> rd"2nd MON" + Date(2019,1,1)
2019-01-14
julia> RDates.NthWeekdays(:MON, 5) + Date(2019,1,1)
ERROR: ArgumentError: Day: 35 out of range (1:31)
```
"""
struct NthWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
    NthWeekdays(dayofweek::Symbol, period::Int64) = new(RDates.WEEKDAYS[dayofweek], period)
end

function apply(rdate::NthWeekdays, date::Dates.Date, cal_mgr::CalendarManager)
    wd = Dates.dayofweek(date)
    wd1st = mod(wd - mod(Dates.day(date), 7), 7) + 1
    wd1stdiff = wd1st - rdate.dayofweek
    period = wd1stdiff > 0 ? rdate.period : rdate.period - 1
    days = 7*period - wd1stdiff + 1
    return Dates.Date(Dates.year(date), Dates.month(date), days)
end
multiply(x::NthWeekdays, ::Integer) = x
Base.:-(x::NthWeekdays) = x

Base.show(io::IO, rdate::NthWeekdays) = print(io, "$(NTH_PERIODS[rdate.period]) $(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")

register_grammar!(Alt(map(Pattern, NTH_PERIODS)...) + space + weekday_short > (p,wd) -> NthWeekdays(WEEKDAYS[Symbol(wd)], PERIODS[p]))

"""
    NthLastWeekdays(dayofweek::Int64, period::Int64)
    NthLastWeekdays(dayofweek::Symbol, period::Int64)

Move to the nth last weekday in the given month and year. This is commonly used for holiday
calendars, such as the Spring Bank Holiday in the UK, which is the last Monday in May.

!!! note
    It's possible that a given period (such as the 5th Last weekday) may exist for only
    a subsection of dates. While it's a valid RDate it may not produce valid results
    when applied (and will throw an exception)

### Examples
```julia-repl
julia> RDates.NthLastWeekdays(:MON, 2) + Date(2019,1,1)
2019-01-21
julia> RDates.NthLastWeekdays(1, 2) + Date(2019,1,1)
2019-01-21
julia> rd"2nd Last MON" + Date(2019,1,1)
2019-01-21
julia> RDates.NthLastWeekdays(:MON, 5) + Date(2019,1,1)
ERROR: ArgumentError: Day: 0 out of range (1:31)
```
"""
struct NthLastWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthLastWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
    NthLastWeekdays(dayofweek::Symbol, period::Int64) = new(RDates.WEEKDAYS[dayofweek], period)
end

function apply(rdate::NthLastWeekdays, date::Dates.Date, cal_mgr::CalendarManager)
    ldom = LDOM() + date
    ldom_dow = Dates.dayofweek(ldom)
    ldom_dow_diff = ldom_dow - rdate.dayofweek
    period = ldom_dow_diff >= 0 ? rdate.period - 1 : rdate.period
    days_to_sub = 7*period + ldom_dow_diff
    days = Dates.day(ldom) - days_to_sub
    return Dates.Date(Dates.year(date), Dates.month(date), days)
end

multiply(x::NthLastWeekdays, ::Integer) = x
Base.:-(x::NthLastWeekdays) = x

Base.show(io::IO, rdate::NthLastWeekdays) = print(io, "$(NTH_LAST_PERIODS[rdate.period]) $(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")

register_grammar!(Alt(map(Pattern, NTH_LAST_PERIODS)...) + space + weekday_short > (p,wd) -> NthLastWeekdays(WEEKDAYS[Symbol(wd)], PERIODS[p]))


"""
    Weekdays(dayofweek::Int64, count::Int64, inclusive::Bool = false)
    Weekdays(dayofweek::Symbol, count::Int64, inclusive::Bool = false)

Provides a mechanism to ask for the next Saturday or the last Tuesday. The count specifies
what we're looking for. `Weekdays(:MON, 1)` will ask for the next Monday, exclusive of the
date started from. You can make it inclusive by passing the inclusive parameter with
`Weekdays(:MON, 1, true)`.

!!! note
    A count of `0` is not supported as it doesn't specify what you're actually looking for!

Incrementing the count will then be additional weeks (forward or backwards) from the single
count point.

### Examples
```julia-repl
julia> RDates.Weekdays(:WED, 1) + Date(2019,9,24) # Tuesday
2019-09-25
julia> RDates.Weekdays(3, 1) + Date(2019,9,24)
2019-09-25
julia> rd"1WED" + Date(2019,9,24)
2019-09-25
julia> RDates.Weekdays(:WED, 1) + Date(2019,9,25)
2019-10-02
julia> RDates.Weekdays(:WED, 1, true) + Date(2019,9,25)
2019-09-25
julia> rd"1WED!" + Date(2019,9,25)
2019-09-25
julia> RDates.Weekdays(:WED, -1) + Date(2019,9,24)
2019-09-18
```
"""
struct Weekdays <: RDate
    dayofweek::Int64
    count::Int64
    inclusive::Bool

    function Weekdays(dayofweek::Int64, count::Int64, inclusive::Bool = false)
        count != 0 || error("Cannot create 0 Weekdays")
        new(dayofweek, count, inclusive)
    end

    function Weekdays(dayofweek::Symbol, count::Int64, inclusive::Bool = false)
        count != 0 || error("Cannot create 0 Weekdays")
        new(WEEKDAYS[dayofweek], count, inclusive)
    end
end

function apply(rdate::Weekdays, date::Dates.Date, cal_mgr::CalendarManager)
    dayδ = Dates.dayofweek(date) - rdate.dayofweek
    weekδ = rdate.count

    if rdate.count < 0 && (dayδ > 0 || (rdate.inclusive && dayδ == 0))
        weekδ += 1
    elseif rdate.count > 0 && (dayδ < 0 || (rdate.inclusive && dayδ == 0))
        weekδ -= 1
    end

    return date + Dates.Day(weekδ*7 - dayδ)
end

multiply(x::Weekdays, count::Integer) = Weekdays(x.dayofweek, x.count * count, x.inclusive)
Base.:-(rdate::Weekdays) = Weekdays(rdate.dayofweek, -rdate.count)

function Base.show(io::IO, rdate::Weekdays)
    weekday = uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek])
    inclusive = rdate.inclusive ? "!" : ""
    print(io, "$(rdate.count)$weekday$inclusive")
end
register_grammar!(PNonZeroInt64() + weekday_short > (i,wd) -> Weekdays(WEEKDAYS[Symbol(wd)], i))
register_grammar!(PNonZeroInt64() + weekday_short + E"!" > (i,wd) -> Weekdays(WEEKDAYS[Symbol(wd)], i, true))

"""
    BizDayZero

Wrapper for a zero day count in business days, which holds the direction. Direction
can either be :next or :prev
"""
struct BizDayZero
    direction::Symbol

    function BizDayZero(direction::Symbol)
        direction in (:next, :prev) || error("unknown direction $direction for BizDayZero")
        new(direction)
    end
end

function Base.:-(x::BizDayZero)
    BizDayZero(x.direction == :next ? :prev : :next)
end

"""
    BizDays(days::Int64, calendars)
    BizDays(days::BizDayZero)

It can be handy to work in business days at times, rather than calendar days. This
allows us to move forwards or backwards `n` days.

```julia-repl
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(RDates.BizDays(1, "WEEKEND"), Date(2021,7,9), cal_mgr)
2021-07-12
julia> apply(rd"1b@WEEKEND", Date(2021,7,9), cal_mgr)
2021-07-12
julia> apply(RDates.BizDays(-10, "WEEKEND"), Date(2021,7,9), cal_mgr)
2021-06-25
```

If the date falls on a holiday, then it is first moved forward (or backwards) to a valid
business day.

```julia-repl
julia> apply(RDates.BizDays(1, "WEEKEND"), Date(2021,7,10), cal_mgr)
2021-07-13
```

For zero business days, we could either want to move forwards or backwards. As such we
provide `BizDayZero` which can be used to provide each. By default, `0b` will move forward

```julia-repl
julia> apply(RDates.BizDays(RDates.BizDayZero(:next), "WEEKEND"), Date(2021,7,10), cal_mgr)
2021-07-12
julia> apply(RDates.BizDays(RDates.BizDayZero(:prev), "WEEKEND"), Date(2021,7,10), cal_mgr)
2021-07-09
julia> apply(rd"0b@WEEKEND", Date(2021,7,10), cal_mgr)
2021-07-12
julia> apply(rd"-0b@WEEKEND", Date(2021,7,10), cal_mgr)
2021-07-09
```
"""
@auto_hash_equals struct BizDays <: RDate
    days::Union{Int64, BizDayZero}
    calendar_names::Vector{String}

    function BizDays(days::Int64, calendar_names)
        days = days != 0 ? days : BizDayZero(:next)
        new(days, calendar_names)
    end

    BizDays(days::Int64, calendar_names::String) = BizDays(days, split(calendar_names, "|"))

    BizDays(days::BizDayZero, calendar_names) = new(days, calendar_names)
    BizDays(days::BizDayZero, calendar_names::String) = new(days, split(calendar_names, "|"))
end

function apply(rdate::BizDays, date::Dates.Date, cal_mgr::CalendarManager)
    cal = calendar(cal_mgr, rdate.calendar_names)
    if isa(rdate.days, BizDayZero)
        rounding = rdate.days.direction == :next ? HolidayRoundingNBD() : HolidayRoundingPBD()
        apply(rounding, date, cal)
    else
        rounding = rdate.days > 0 ? HolidayRoundingNBD() : HolidayRoundingPBD()
        date = apply(rounding, date, cal)

        count = rdate.days
        if rdate.days > 0
            while count > 0
                date = apply(rounding, date + Dates.Day(1), cal)
                count -= 1
            end
        elseif rdate.days < 0
            while count < 0
                date = apply(rounding, date - Dates.Day(1), cal)
                count += 1
            end
        end

        date
    end
end

function multiply(x::BizDays, count::Integer)
    x = count < 0 ? -x : x
    days = isa(x.days, BizDayZero) ? x.days : x.days * abs(count)
    return BizDays(days, x.calendar_names)
end

Base.:-(x::BizDays) = BizDays(-x.days, x.calendar_names)
register_grammar!(PPosZeroInt64() + E"b@" + PCalendarNames() > (days,calendar_name) -> BizDays(days, map(String, split(calendar_name, "|"))))
