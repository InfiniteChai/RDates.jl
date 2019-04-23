import Dates
using Compat

const WEEKDAYS = Dict(zip(map(Symbol ∘ uppercase, Dates.ENGLISH.days_of_week_abbr),range(1,stop=7)))
const MONTHS = Dict(zip(map(Symbol ∘ uppercase, Dates.ENGLISH.months_abbr),range(1,stop=12)))

@compat abstract type RDate end
apply(rdate::RDate, date::Dates.Date) = error("$(typeof(rdate)) does not support 'apply'")
apply(date::Dates.Date, rdate::RDate) = apply(rdate, date)
negate(rdate::RDate) = error("$(typeof(rdate)) does not support 'negate'")

struct Day <: RDate
    days::Int64
end

apply(rdate::Day, date::Dates.Date) = date + Dates.Day(rdate.days)
negate(rdate::Day) = Day(-rdate.days)

struct Week <: RDate
    weeks::Int64
end

apply(rdate::Week, date::Dates.Date) = date + Dates.Week(rdate.weeks)
negate(rdate::Week) = Week(-rdate.weeks)

struct FDOM <: RDate end
apply(rdate::FDOM, date::Dates.Date) = Dates.firstdayofmonth(date)

struct LDOM <: RDate end
apply(rdate::LDOM, date::Dates.Date) = Dates.lastdayofmonth(date)

struct Month <: RDate
    months::Int64
    idc::InvalidDay.InvalidDayConvention
    mic::MonthIncrement.MonthIncrementConvention

    Month(months::Int64) = new(months, InvalidDay.LDOM, MonthIncrement.PDOM)
    Month(months::Int64, idc::InvalidDay.InvalidDayConvention, mic::MonthIncrement.MonthIncrementConvention) = new(months, idc, mic)
end

function apply(rdate::Month, date::Dates.Date)
    y,m,d = Dates.yearmonthday(date)
    ny = Dates.yearwrap(y, m, rdate.months)
    nm = Dates.monthwrap(m, rdate.months)
    (ay, am, ad) = MonthIncrement.adjust(rdate.mic, d, m, y, nm, ny)
    ld = Dates.daysinmonth(ay, am)
    return ad <= ld ? Dates.Date(ay, am, ad) : InvalidDay.adjust(rdate.idc, ad, am, ay)
end

negate(rdate::Month) = Month(-rdate.months)

struct Year <: RDate
    years::Int64
    idm::InvalidDay.InvalidDayConvention

    Year(years::Int64) = new(years, InvalidDay.LDOM)
    Year(years::Int64, idm::InvalidDay.InvalidDayConvention) = new(years, idm)
end

function apply(rdate::Year, date::Dates.Date)
    oy, m, d = Dates.yearmonthday(date)
    ny = oy + rdate.years
    ld = Dates.daysinmonth(ny, m)
    return d <= ld ? Dates.Date(ny, m, d) : InvalidDay.adjust(rdate.idm, d, m, ny)
end

negate(rdate::Year) = Year(-rdate.years)

struct DayMonth <: RDate
    day::Int64
    month::Int64

    DayMonth(day::Int64, month::Int64) = new(day, month)
end

apply(rdate::DayMonth, date::Dates.Date) = Dates.Date(Dates.year(date), rdate.month, rdate.day)

struct Easter <: RDate
    yearδ::Int64
end
function apply(rdate::Easter, date::Dates.Date)
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

negate(rdate::Easter) = Easter(-rdate.yearδ)

struct NthWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
end

function apply(rdate::NthWeekdays, date::Dates.Date)
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

function apply(rdate::NthLastWeekdays, date::Dates.Date)
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

function apply(rdate::Weekdays, date::Dates.Date)
    dayδ = Dates.dayofweek(date) - rdate.dayofweek
    weekδ = rdate.count

    if rdate.count < 0 && dayδ > 0
        weekδ += 1
    elseif rdate.count > 0 && dayδ < 0
        weekδ -= 1
    end

    return date + Dates.Day(weekδ*7 - dayδ)
end

negate(rdate::Weekdays) = Weekdays(rdate.dayofweek, -rdate.count)

struct RDateCompound <: RDate
    parts::Vector{RDate}
end
Base.:(==)(x::RDateCompound, y::RDateCompound) = x.parts == y.parts

apply(rdate::RDateCompound, date::Dates.Date) = Base.foldl(apply, rdate.parts, init=date)
combine(left::RDate, right::RDate) = RDateCompound([left,right])

struct RDateRepeat <: RDate
    count::Int64
    part::RDate
end
Base.:(==)(x::RDateRepeat, y::RDateRepeat) = x.count == y.count && x.part == y.part

apply(rdate::RDateRepeat, date::Dates.Date) = Base.foldl(apply, fill(rdate.part, rdate.count), init=date)
negate(rdate::RDateRepeat) = RDateRepeat(rdate.count, negate(rdate.part))

Base.:+(rdate::RDate, date::Dates.Date) = apply(rdate, date)
Base.:+(left::RDate, right::RDate) = combine(left, right)
Base.:-(left::RDate, right::RDate) = combine(left, negate(right))
Base.:+(date::Dates.Date, rdate::RDate) = apply(rdate, date)
Base.:-(date::Dates.Date, rdate::RDate) = apply(negate(rdate), date)
Base.:*(count::Number, rdate::RDate) = RDateRepeat(count, rdate)
Base.:*(rdate::RDate, count::Number) = RDateRepeat(count, rdate)

struct RDateRange
    from::Dates.Date
    to::Union{Dates.Date, Nothing}
    period::RDate
    inc_from::Bool
    inc_to::Bool
end

function Base.iterate(iter::RDateRange, state=nothing)
    if state === nothing
        state = (iter.inc_from ? iter.from : iter.from + iter.period, 0)
    end
    elem, count = state
    op = iter.inc_to ? Base.:> : Base.:>=
    if iter.to !== nothing && op(elem,iter.to)
        return nothing
    end

    return (elem, (elem + iter.period, count + 1))
end

Base.IteratorSize(::Type{RDateRange}) = Base.SizeUnknown()
Base.eltype(::Type{RDateRange}) = Dates.Date
function Base.range(from::Dates.Date, period::RDate; inc_from::Bool=true, inc_to::Bool=true)
    return RDateRange(from, nothing, period, inc_from, inc_to)
end

function Base.range(from::Dates.Date, to::Dates.Date, period::RDate; inc_from::Bool=true, inc_to::Bool=true)
    return RDateRange(from, to, period, inc_from, inc_to)
end
