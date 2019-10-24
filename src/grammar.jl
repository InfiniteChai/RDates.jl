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

    brackets = E"(" + space + sum + space + E")"

    rdate_term = Alt()
    rdate_expr = rdate_term | brackets

    neg = Delayed()
    neg.matcher = rdate_expr | (E"-" + neg > -)
    cal_adj = neg + (E"@" + p"[a-zA-Z\\\\\\s\\|]+" + E"[" + Alt(map(Pattern, collect(keys(HOLIDAY_ROUNDING_MAPPINGS)))...) + E"]")[0:1] |> xs -> length(xs) == 1 ? xs[1] : CalendarAdj(map(String, split(xs[2], "|")), xs[1], HOLIDAY_ROUNDING_MAPPINGS[xs[3]])

    # Our decision on the grammar choice for rdates is purely one of history.
    # * will imply 'no roll', so 2*1m == 2m
    # *roll will imply 'roll', so 2*roll(1m) == 1m + 1m
    mult_roll = cal_adj | ((PPosInt64() + space + E"*" + space + E"roll(" + space + sum + space + E")") > (c, rd) -> multiply_roll(rd, c)) | ((E"roll(" + space + sum + space + E")" + space + E"*" + space + PPosInt64()) > (rd, c) -> multiply_roll(rd, c))

    mult_no_roll = Delayed()
    mult_no_roll = mult_roll | ((PPosInt64() + space + E"*" + space + mult_roll) > (c,rd) -> multiply_no_roll(rd, c)) | ((mult_roll + space + E"*" + space + PPosInt64()) > (rd,c) -> multiply_no_roll(rd, c))

    add = E"+" + mult_no_roll
    sub = E"-" + mult_no_roll > -
    sum.matcher = (sub | mult_no_roll) + (add | mult_no_roll)[0:end] |> Base.sum

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
