import Dates
using Compat

const WEEKDAYS = Dict(zip(map(Symbol ∘ uppercase, Dates.ENGLISH.days_of_week_abbr),range(1,stop=7)))
const MONTHS = Dict(zip(map(Symbol ∘ uppercase, Dates.ENGLISH.months_abbr),range(1,stop=12)))

@compat abstract type RDate end

Base.:+(x::RDate, y::Dates.Date) = error("$(typeof(x)) does not support date addition")
Base.:+(x::Dates.Date, y::RDate) = y + x
Base.:-(x::RDate) = error("$(typeof(x)) does not support negation")

struct Day <: RDate
    days::Int64
end

Base.:+(x::Day, y::Dates.Date) = y + Dates.Day(x.days)
Base.:-(x::Day) = Day(-x.days)
Base.:+(x::Day, y::Day) = Day(x.days + y.days)

struct Week <: RDate
    weeks::Int64
end

Base.:+(x::Week, y::Dates.Date) = y + Dates.Week(x.weeks)
Base.:-(x::Week) = Week(-x.weeks)
Base.:+(x::Week, y::Week) = Week(x.weeks + y.weeks)

struct FDOM <: RDate end
Base.:+(x::FDOM, y::Dates.Date) = Dates.firstdayofmonth(y)

struct LDOM <: RDate end
Base.:+(x::LDOM, y::Dates.Date) = Dates.lastdayofmonth(y)

struct Month <: RDate
    months::Int64
    idc::InvalidDay.InvalidDayConvention
    mic::MonthIncrement.MonthIncrementConvention

    Month(months::Int64) = new(months, InvalidDay.LDOM, MonthIncrement.PDOM)
    Month(months::Int64, idc::InvalidDay.InvalidDayConvention, mic::MonthIncrement.MonthIncrementConvention) = new(months, idc, mic)
end

function Base.:+(rdate::Month, date::Dates.Date)
    y,m,d = Dates.yearmonthday(date)
    ny = Dates.yearwrap(y, m, rdate.months)
    nm = Dates.monthwrap(m, rdate.months)
    (ay, am, ad) = MonthIncrement.adjust(rdate.mic, d, m, y, nm, ny)
    ld = Dates.daysinmonth(ay, am)
    return ad <= ld ? Dates.Date(ay, am, ad) : InvalidDay.adjust(rdate.idc, ad, am, ay)
end

Base.:-(x::Month) = Month(-x.months)

struct Year <: RDate
    years::Int64
    idm::InvalidDay.InvalidDayConvention

    Year(years::Int64) = new(years, InvalidDay.LDOM)
    Year(years::Int64, idm::InvalidDay.InvalidDayConvention) = new(years, idm)
end

function Base.:+(rdate::Year, date::Dates.Date)
    oy, m, d = Dates.yearmonthday(date)
    ny = oy + rdate.years
    ld = Dates.daysinmonth(ny, m)
    return d <= ld ? Dates.Date(ny, m, d) : InvalidDay.adjust(rdate.idm, d, m, ny)
end

Base.:-(x::Year) = Year(-x.years)

struct DayMonth <: RDate
    day::Int64
    month::Int64

    DayMonth(day::Int64, month::Int64) = new(day, month)
end

Base.:+(rdate::DayMonth, date::Dates.Date) = Dates.Date(Dates.year(date), rdate.month, rdate.day)

struct Easter <: RDate
    yearδ::Int64
end
function Base.:+(rdate::Easter, date::Dates.Date)
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

struct NthWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
end

function Base.:+(rdate::NthWeekdays, date::Dates.Date)
    wd = Dates.dayofweek(date)
    wd1st = mod(wd - mod(Dates.day(date), 7), 7) + 1
    wd1stdiff = wd1st - rdate.dayofweek
    period = wd1stdiff > 0 ? rdate.period : rdate.period - 1
    days = 7*period - wd1stdiff + 1
    return Dates.Date(Dates.year(date), Dates.month(date), days)
end

struct NthLastWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthLastWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
end

function Base.:+(rdate::NthLastWeekdays, date::Dates.Date)
    ldom = LDOM() + date
    ldom_dow = Dates.dayofweek(ldom)
    ldom_dow_diff = ldom_dow - rdate.dayofweek
    period = ldom_dow_diff >= 0 ? rdate.period - 1 : rdate.period
    days_to_sub = 7*period + ldom_dow_diff
    days = Dates.day(ldom) - days_to_sub
    return Dates.Date(Dates.year(date), Dates.month(date), days)
end

struct Weekdays <: RDate
    dayofweek::Int64
    count::Int64

    Weekdays(dayofweek::Int64, count::Int64) = new(dayofweek, count)
end

function Base.:+(rdate::Weekdays, date::Dates.Date)
    dayδ = Dates.dayofweek(date) - rdate.dayofweek
    weekδ = rdate.count

    if rdate.count < 0 && dayδ > 0
        weekδ += 1
    elseif rdate.count > 0 && dayδ < 0
        weekδ -= 1
    end

    return date + Dates.Day(weekδ*7 - dayδ)
end

Base.:-(rdate::Weekdays) = Weekdays(rdate.dayofweek, -rdate.count)

struct RDateCompound <: RDate
    parts::Vector{RDate}
end
Base.:(==)(x::RDateCompound, y::RDateCompound) = x.parts == y.parts

Base.:+(rdate::RDateCompound, date::Dates.Date) = Base.foldl(+, rdate.parts, init=date)
Base.:-(rdate::RDateCompound) = RDateCompound(map(-, rdate.parts))
Base.:+(x::RDateCompound, y::RDate) = RDateCompound(vcat(x.parts, y))
Base.:+(x::RDate, y::RDateCompound) = RDateCompound(vcat(x, y.parts))
combine(left::RDate, right::RDate) = RDateCompound([left,right])

struct RDateRepeat <: RDate
    count::Int64
    part::RDate
end
Base.:(==)(x::RDateRepeat, y::RDateRepeat) = x.count == y.count && x.part == y.part

Base.:+(rdate::RDateRepeat, date::Dates.Date) = Base.foldl(+, fill(rdate.part, rdate.count), init=date)
Base.:-(rdate::RDateRepeat) = RDateRepeat(rdate.count, -rdate.part)

Base.:+(left::RDate, right::RDate) = combine(left, right)
Base.:-(left::RDate, right::RDate) = combine(left, -right)
Base.:*(count::Number, rdate::RDate) = RDateRepeat(count, rdate)
Base.:*(rdate::RDate, count::Number) = RDateRepeat(count, rdate)
