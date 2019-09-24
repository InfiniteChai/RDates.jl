using ParserCombinator
import Dates

space = Drop(Star(Space()))

PNonZeroInt64() = Parse(p"-?[1-9][0-9]*", Int64)
PPosInt64() = Parse(p"[1-9][0-9]*", Int64)
PPosZeroInt64() = Parse(p"[0-9][0-9]*", Int64)

@with_pre space begin
    sum = Delayed()

    weekday_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.days_of_week_abbr)...)
    month_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.months_abbr)...)

    rdate_term = Alt()
    rdate_expr = rdate_term | (E"(" + space + sum + space + E")")

    # Add support for multiple negatives --2d for example...

    neg = Delayed()
    neg.matcher = rdate_expr | (E"-" + neg > -)
    cal_adj = neg + (E"@" + p"[a-zA-Z\\\\\\s\\|]+" + E"[" + Alt(map(Pattern, collect(keys(HOLIDAY_ROUNDING_MAPPINGS)))...) + E"]")[0:1] |> xs -> length(xs) == 1 ? xs[1] : CalendarAdj(xs[2], xs[1], HOLIDAY_ROUNDING_MAPPINGS[xs[3]])
    mul = E"*" + (cal_adj | PPosInt64())
    prod = (cal_adj | ((PPosInt64() | cal_adj) + mul[0:end])) |> Base.prod
    add = E"+" + prod
    sub = E"-" + prod > -
    sum.matcher = prod + (add | sub)[0:end] |> Base.sum

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
