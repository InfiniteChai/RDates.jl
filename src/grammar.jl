using ParserCombinator
using Dates

const WEEKDAYS = Dict(zip(map(uppercase, Dates.ENGLISH.days_of_week_abbr),range(1,stop=7)))
const MONTHS = Dict(zip(map(uppercase, Dates.ENGLISH.months_abbr),range(1,stop=12)))
space = Drop(Star(Space()))

PNonZeroInt64() = Parse(p"-?[1-9][0-9]*", Int64)
PPosInt64() = Parse(p"[1-9][0-9]*", Int64)

@with_pre space begin
    sum = Delayed()
    d = PInt64() + E"d" > RDateDay
    w = PInt64() + E"w" > RDateWeek
    m = PInt64() + E"m" > RDateMonth
    y = PInt64() + E"y" > RDateYear
    fdom = E"FDOM" > RDateFDOM
    ldom = E"LDOM" > RDateLDOM
    easter = PInt64() + E"E" > RDateEaster
    weekday_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.days_of_week_abbr)...)
    month_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.months_abbr)...)
    weekday = PNonZeroInt64() + weekday_short > (i,wd) -> RDateWeekdays(WEEKDAYS[wd], i)
    day_month = PPosInt64() + month_short > (d,m) -> RDateDayMonth(d,MONTHS[m])

    rdate_term = d | w | m | y | fdom | ldom | easter | weekday | day_month
    rdate = rdate_term | (E"(" + space + sum + space + E")")

    # Add support for multiple negatives --2d for example...
    neg = Delayed()
    neg.matcher = rdate | (E"-" + neg > negate)

    mul = E"*" + (neg | PPosInt64())
    prod = (neg | ((PPosInt64() | neg) + mul[0:end])) |> Base.prod
    add = E"+" + prod
    sub = E"-" + prod > negate
    sum.matcher = prod + (add | sub)[0:end] |> x -> length(x) == 1 ? x[1] : RDateCompound(x)

    rdate_expr = sum + Eos()
end

macro rd_str(arg)
    return parse_one(arg, rdate_expr)[1]
end
