using ParserCombinator
import Dates

const NTH_PERIODS = ["1st", "2nd", "3rd", "4th", "5th"]
const NTH_LAST_PERIODS = ["Last", "2nd Last", "3rd Last", "4th Last", "5th Last"]

const PERIODS = Dict(
    "1st" => 1, "2nd" => 2, "3rd" => 3, "4th" => 4, "5th" => 5,
    "Last" => 1, "2nd Last" => 2, "3rd Last" => 3, "4th Last" => 4, "5th Last" => 5)

space = Drop(Star(Space()))

PNonZeroInt64() = Parse(p"-?[1-9][0-9]*", Int64)
PPosInt64() = Parse(p"[1-9][0-9]*", Int64)

@with_pre space begin
    sum = Delayed()
    d = PInt64() + E"d" > Day
    w = PInt64() + E"w" > Week
    m = PInt64() + E"m" > Month
    enhanced_m = PInt64() + E"m[" + Alt(map(Pattern, collect(keys(InvalidDay.MAPPINGS)))...) + E";" + Alt(map(Pattern, collect(keys(MonthIncrement.MAPPINGS)))...) + E"]" > (d,idc,mic) -> Month(d, InvalidDay.MAPPINGS[idc], MonthIncrement.MAPPINGS[mic])
    y = PInt64() + E"y" > Year
    enhanced_y = PInt64() + E"y[" + Alt(map(Pattern, collect(keys(InvalidDay.MAPPINGS)))...)+ E"]" > (d,idc) -> Year(d, InvalidDay.MAPPINGS[idc])
    fdom = E"FDOM" > FDOM
    ldom = E"LDOM" > LDOM
    easter = PInt64() + E"E" > Easter
    weekday_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.days_of_week_abbr)...)
    month_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.months_abbr)...)
    weekday = PNonZeroInt64() + weekday_short > (i,wd) -> Weekdays(WEEKDAYS[Symbol(wd)], i)
    day_month = PPosInt64() + month_short > (d,m) -> DayMonth(d,MONTHS[Symbol(m)])
    nth_weekdays = (p"1st" | p"2nd" | p"3rd" | p"4th" | p"5th") + space + weekday_short > (p,wd) -> NthWeekdays(WEEKDAYS[Symbol(wd)], PERIODS[p])
    nth_last_weekdays = (p"Last" | p"2nd Last" | p"3rd Last" | p"4th Last" | p"5th Last") + space + weekday_short > (p,wd) -> NthLastWeekdays(WEEKDAYS[Symbol(wd)], PERIODS[p])

    rdate_term = d | w | m | enhanced_m | y | enhanced_y | fdom | ldom | easter | weekday | day_month | nth_weekdays | nth_last_weekdays
    rdate_expr = rdate_term | (E"(" + space + sum + space + E")")

    # Add support for multiple negatives --2d for example...
    neg = Delayed()
    neg.matcher = rdate_expr | (E"-" + neg > -)

    mul = E"*" + (neg | PPosInt64())
    prod = (neg | ((PPosInt64() | neg) + mul[0:end])) |> Base.prod
    add = E"+" + prod
    sub = E"-" + prod > -
    sum.matcher = prod + (add | sub)[0:end] |> Base.sum

    entry = sum + Eos()
end

macro rd_str(arg::String)
    val = parse_one(arg, entry)[1]
    isa(val, RDate) || error("Unable to parse $(arg) as RDate")
    return val
end

function rdate(arg::String)
    val = parse_one(arg, entry)[1]
    isa(val, RDate) || error("Unable to parse $(arg) as RDate")
    return val
end
