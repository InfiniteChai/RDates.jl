import Dates
import StaticArrays

const WEEKDAYS = Dict(map(reverse,enumerate(map(Symbol ∘ uppercase, Dates.ENGLISH.days_of_week_abbr))))
const NTH_PERIODS = ["1st", "2nd", "3rd", "4th", "5th"]
const NTH_LAST_PERIODS = ["Last", "2nd Last", "3rd Last", "4th Last", "5th Last"]
const PERIODS = merge(Dict(map(reverse,enumerate(NTH_PERIODS))), Dict(map(reverse,enumerate(NTH_LAST_PERIODS))))
const MONTHS = Dict(zip(map(Symbol ∘ uppercase, Dates.ENGLISH.months_abbr),range(1,stop=12)))

struct FDOM <: RDate end
apply(::FDOM, d::Dates.Date, cal_mgr::CalendarManager) = Dates.firstdayofmonth(d)
Base.:*(x::FDOM, count::Number) = x
Base.show(io::IO, ::FDOM) = print(io, "FDOM")
register_grammar!(E"FDOM" > FDOM)

struct LDOM <: RDate end
apply(::LDOM, d::Dates.Date, cal_mgr::CalendarManager) = Dates.lastdayofmonth(d)
Base.:*(x::LDOM, count::Number) = x
Base.show(io::IO, ::LDOM) = print(io, "LDOM")
register_grammar!(E"LDOM" > LDOM)

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

Base.:-(rdate::Easter) = Easter(-rdate.yearδ)
Base.:*(x::Easter, count::Number) = Easter(x.yearδ*count)
Base.show(io::IO, rdate::Easter) = print(io, "$(rdate.yearδ)E")
register_grammar!(PInt64() + E"E" > Easter)

struct Day <: RDate
    days::Int64
end

apply(x::Day, y::Dates.Date, cal_mgr::CalendarManager) = y + Dates.Day(x.days)
Base.:-(x::Day) = Day(-x.days)
Base.:+(x::Day, y::Day) = Day(x.days + y.days)
Base.:*(x::Day, count::Number) = Day(x.days*count)

Base.show(io::IO, rdate::Day) = print(io, "$(rdate.days)d")
register_grammar!(PInt64() + E"d" > Day)


struct Week <: RDate
    weeks::Int64
end

apply(x::Week, y::Dates.Date, cal_mgr::CalendarManager) = y + Dates.Week(x.weeks)
Base.:-(x::Week) = Week(-x.weeks)
Base.:+(x::Week, y::Week) = Week(x.weeks + y.weeks)
Base.:+(x::Day, y::Week) = Day(x.days + 7*y.weeks)
Base.:+(x::Week, y::Day) = Day(7*x.weeks + y.days)
Base.:*(x::Week, count::Number) = Week(x.weeks*count)
Base.show(io::IO, rdate::Week) = print(io, "$(rdate.weeks)w")
register_grammar!(PInt64() + E"w" > Week)

struct Month <: RDate
    months::Int64
    idc::InvalidDayConvention
    mic::MonthIncrementConvention

    Month(months::Int64) = new(months, InvalidDayLDOM(), MonthIncrementPDOM())
    Month(months::Int64, idc::InvalidDayConvention, mic::MonthIncrementConvention) = new(months, idc, mic)
end

function apply(rdate::Month, date::Dates.Date, cal_mgr::CalendarManager)
    y,m,d = Dates.yearmonthday(date)
    ny = Dates.yearwrap(y, m, rdate.months)
    nm = Dates.monthwrap(m, rdate.months)
    (ay, am, ad) = adjust(rdate.mic, d, m, y, nm, ny)
    ld = Dates.daysinmonth(ay, am)
    return ad <= ld ? Dates.Date(ay, am, ad) : adjust(rdate.idc, ad, am, ay)
end

Base.:-(x::Month) = Month(-x.months)

Base.show(io::IO, rdate::Month) = (print(io, "$(rdate.months)m["), show(io, rdate.idc), print(io, ";"), show(io, rdate.mic), print(io,"]"))
register_grammar!(PInt64() + E"m" > Month)
register_grammar!(PInt64() + E"m[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";" + Alt(map(Pattern, collect(keys(MONTH_INCREMENT_MAPPINGS)))...) + E"]" > (d,idc,mic) -> Month(d, INVALID_DAY_MAPPINGS[idc], MONTH_INCREMENT_MAPPINGS[mic]))

struct Year <: RDate
    years::Int64
    idc::InvalidDayConvention
    mic::MonthIncrementConvention

    Year(years::Int64) = new(years, InvalidDayLDOM(), MonthIncrementPDOM())
    Year(years::Int64, idc::InvalidDayConvention, mic::MonthIncrementConvention) = new(years, idc, mic)
end

function apply(rdate::Year, date::Dates.Date, cal_mgr::CalendarManager)
    oy, m, d = Dates.yearmonthday(date)
    ny = oy + rdate.years
    (ay, am, ad) = adjust(rdate.mic, d, m, oy, m, ny)
    ld = Dates.daysinmonth(ay, am)
    return ad <= ld ? Dates.Date(ay, am, ad) : adjust(rdate.idc, ad, am, ay)
end

Base.:-(x::Year) = Year(-x.years)

Base.show(io::IO, rdate::Year) = (print(io, "$(rdate.years)y["), show(io, rdate.idc), print(io, ";"), show(io, rdate.mic), print(io,"]"))
register_grammar!(PInt64() + E"y" > Year)
register_grammar!(PInt64() + E"y[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";" + Alt(map(Pattern, collect(keys(MONTH_INCREMENT_MAPPINGS)))...) + E"]" > (d,idc,mic) -> Year(d, INVALID_DAY_MAPPINGS[idc], MONTH_INCREMENT_MAPPINGS[mic]))

struct DayMonth <: RDate
    day::Int64
    month::Int64

    DayMonth(day::Int64, month::Int64) = new(day, month)
end

apply(rdate::DayMonth, date::Dates.Date, cal_mgr::CalendarManager) = Dates.Date(Dates.year(date), rdate.month, rdate.day)
Base.show(io::IO, rdate::DayMonth) = print(io, "$(rdate.day)$(uppercase(Dates.ENGLISH.months_abbr[rdate.month]))")
register_grammar!(PPosInt64() + month_short > (d,m) -> DayMonth(d,MONTHS[Symbol(m)]))

struct DayMonthYear <: RDate
    day::Int64
    month::Int64
    year::Int64

    DayMonthYear(day::Int64, month::Int64, year::Int64) = new(day, month, year)
end

apply(rdate::DayMonthYear, date::Dates.Date, cal_mgr::CalendarManager) = Dates.Date(rdate.year, rdate.month, rdate.day)
Base.:*(x::DayMonthYear, count::Number) = x
Base.show(io::IO, rdate::DayMonthYear) = print(io, "$(rdate.day)$(uppercase(Dates.ENGLISH.months_abbr[rdate.month]))$(rdate.year)")
register_grammar!(PPosInt64() + month_short + PPosInt64() > (d,m,y) -> DayMonthYear(d,MONTHS[Symbol(m)],y))

struct NthWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
end

function apply(rdate::NthWeekdays, date::Dates.Date, cal_mgr::CalendarManager)
    wd = Dates.dayofweek(date)
    wd1st = mod(wd - mod(Dates.day(date), 7), 7) + 1
    wd1stdiff = wd1st - rdate.dayofweek
    period = wd1stdiff > 0 ? rdate.period : rdate.period - 1
    days = 7*period - wd1stdiff + 1
    return Dates.Date(Dates.year(date), Dates.month(date), days)
end

Base.show(io::IO, rdate::NthWeekdays) = print(io, "$(NTH_PERIODS[rdate.period]) $(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")
Base.:*(x::NthWeekdays, count::Number) = x
register_grammar!(Alt(map(Pattern, NTH_PERIODS)...) + space + weekday_short > (p,wd) -> NthWeekdays(WEEKDAYS[Symbol(wd)], PERIODS[p]))

struct NthLastWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthLastWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
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

Base.show(io::IO, rdate::NthLastWeekdays) = print(io, "$(NTH_LAST_PERIODS[rdate.period]) $(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")
Base.:*(x::NthLastWeekdays, count::Number) = x
register_grammar!(Alt(map(Pattern, NTH_LAST_PERIODS)...) + space + weekday_short > (p,wd) -> NthLastWeekdays(WEEKDAYS[Symbol(wd)], PERIODS[p]))

struct Weekdays <: RDate
    dayofweek::Int64
    count::Int64
    inclusive::Bool

    Weekdays(dayofweek::Int64, count::Int64) = new(dayofweek, count, false)
    Weekdays(dayofweek::Int64, count::Int64, inclusive::Bool) = new(dayofweek, count, true)
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

Base.:-(rdate::Weekdays) = Weekdays(rdate.dayofweek, -rdate.count)

Base.show(io::IO, rdate::Weekdays) = print(io, "$(rdate.count)$(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")
register_grammar!(PNonZeroInt64() + weekday_short > (i,wd) -> Weekdays(WEEKDAYS[Symbol(wd)], i))
register_grammar!(PNonZeroInt64() + weekday_short + E"!" > (i,wd) -> Weekdays(WEEKDAYS[Symbol(wd)], i, true))

struct BizDays{S <: HolidayRoundingConvention, T} <: RDate
    days::Int64
    calendar_names::StaticArrays.SVector{T,String}
    rounding::S

    BizDays(days::Int64, calendar_names) = BizDays(days, calendar_names, days >= 0 ? HolidayRoundingNBD() : HolidayRoundingPBD())
    BizDays(days::Int64, calendar_names, rounding::S) where {S <: HolidayRoundingConvention} = new{S,length(calendar_names)}(days, calendar_names, rounding)
end

function apply(rdate::BizDays, date::Dates.Date, cal_mgr::CalendarManager)
    cal = calendar(cal_mgr, rdate.calendar_names)
    count = rdate.days
    if rdate.days > 0
        while count > 0
            date = apply(rdate.rounding, date + Dates.Day(1), cal)
            count -= 1
        end
    elseif rdate.days < 0
        while count < 0
            date = apply(rdate.rounding, date - Dates.Day(1), cal)
            count += 1
        end
    else
        date = apply(rdate.rounding, date, cal)
    end

    return date
end

Base.:-(x::BizDays{HolidayRoundingNBD}) = BizDays(-x.days, x.calendar_names, HolidayRoundingPBD())
Base.:-(x::BizDays{HolidayRoundingPBD}) = BizDays(-x.days, x.calendar_names, HolidayRoundingNBD())

register_grammar!(PPosZeroInt64() + E"b@" + p"[a-zA-Z\\\\\\s\\|]+" > (days,calendar_name) -> BizDays(days, map(String, split(calendar_name, "|"))))
