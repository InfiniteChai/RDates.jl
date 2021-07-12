import ParserCombinator: PInt64, Eos, set_fix, Drop, Star, Space, @with_pre, Parse, @p_str, Pattern, Alt, Delayed, parse_one, @E_str
import Dates

space = Drop(Star(Space()))

PNonZeroInt64() = Parse(p"-?[1-9][0-9]*", Int64)
PPosInt64() = Parse(p"[1-9][0-9]*", Int64)
PPosZeroInt64() = Parse(p"[0-9][0-9]*", Int64)
PCalendarNames() = p"[a-zA-Z0-9-\/\s|]+"

@with_pre space begin
    sum = Delayed()

    weekday_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.days_of_week_abbr)...)
    month_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.months_abbr)...)

    brackets = E"(" + space + sum + space + E")"
    repeat = E"Repeat(" + space + sum + space + E")" > rd -> Repeat(rd)
    rdate_term = Alt()

    next = E"Next(" + (space + sum) + (E"," + space + sum)[0:end] + space + E")" |> parts -> Next(parts)
    next_inc = E"Next!(" + (space + sum) + (E"," + space + sum)[0:end] + space + E")" |> parts -> Next(parts, true)
    previous = E"Previous(" + (space + sum) + (E"," + space + sum)[0:end] + space + E")" |> parts -> Previous(parts)
    previous_inc = E"Previous!(" + (space + sum) + (E"," + space + sum)[0:end] + space + E")" |> parts -> Previous(parts, true)

    rdate_expr = rdate_term | brackets | repeat | next | next_inc | previous | previous_inc

    neg = Delayed()
    neg.matcher = rdate_expr | (E"-" + neg > -)
    cal_adj = neg + (E"@" + PCalendarNames() + E"[" + Alt(map(Pattern, collect(keys(HOLIDAY_ROUNDING_MAPPINGS)))...) + E"]")[0:1] |> xs -> length(xs) == 1 ? xs[1] : CalendarAdj(map(String, split(xs[2], "|")), xs[1], HOLIDAY_ROUNDING_MAPPINGS[xs[3]])


    mult = Delayed()
    mult = cal_adj | ((PPosInt64() + space + E"*" + space + cal_adj) > (c,rd) -> multiply(rd, c)) | ((cal_adj + space + E"*" + space + PPosInt64()) > (rd,c) -> multiply(rd, c))

    add = E"+" + mult
    sub = E"-" + mult > -
    sum.matcher = (sub | mult) + (add | mult)[0:end] |> Base.sum

    entry = sum + Eos()
end

function register_grammar!(term)
    # Handle the spacing correctly
    push!(rdate_term.matchers[2].matchers, term)
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
