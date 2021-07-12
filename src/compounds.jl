using AutoHashEquals

"""
    Compound <: RDate

Apply a list of rdates in order
"""
@auto_hash_equals struct Compound <: RDate
    parts::Vector{RDate}
end

apply(rdate::Compound, date::Dates.Date, cal_mgr::CalendarManager) = Base.foldl((x,y) -> apply(y, x, cal_mgr), rdate.parts, init=date)
multiply(rdate::Compound, count::Integer) = Compound(map(x -> multiply(x, count), rdate.parts))
combine(left::RDate, right::RDate) = Compound([left,right])
Base.:+(left::RDate, right::RDate) = combine(left, right)
Base.:-(left::RDate, right::RDate) = combine(left, -right)
Base.:-(rdate::Compound) = Compound(map(-, rdate.parts))
Base.:+(x::Compound, y::RDate) = Compound(vcat(x.parts, y))
Base.:+(x::RDate, y::Compound) = Compound(vcat(x, y.parts))

function Base.show(io::IO, rdate::Compound)
    for (i,part) in enumerate(rdate.parts)
        if i > 1 print(io, "+") end
        show(io, part)
    end
end

"""
    Repeat <: RDate

Repeat the application of an rdate n times.
"""
@auto_hash_equals struct Repeat <: RDate
    count::Int64
    part::RDate

    function Repeat(count::Int64, part::RDate)
        count > 0 || error("Repeat must use a positive count, not $count")
        new(count, part)
    end

    Repeat(part::RDate) = new(1, part)
end

function apply(rdate::Repeat, date::Dates.Date, cal_mgr::CalendarManager)
    for _ in 1:rdate.count
        date = apply(rdate.part, date, cal_mgr)
    end
    date
end

multiply(rdate::Repeat, count::Integer) = Repeat(count*rdate.count, rdate.part)
Base.:-(rdate::Repeat) = Repeat(rdate.count, -rdate.part)
Base.show(io::IO, rdate::Repeat) = (print(io, "$(rdate.count)*Repeat("), show(io, rdate.part), print(io,")"))

"""
    CalendarAdj(calendars, rdate::RDate, rounding::HolidayRoundingConvention)

Apply a calendar adjustment to an underlying rdate, applying an appropriate convention if
our final date falls on a holiday.

The calendars can only use alphanumeric characters, plus `/`, `-` and ` `.

In the string-form, you can apply a calendar adjustment using the `@` character and
provide `|` separated calendar names to apply it on. The convention is finally provided in
square brackets using its string-form name.

### Examples
```julia-repl
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(rd"1d", Date(2019,9,27), cal_mgr)
2019-09-28
julia> apply(rd"1d@WEEKEND[NBD]", Date(2019,9,27), cal_mgr)
2019-09-30
julia> apply(rd"2m - 1d", Date(2019,7,23), cal_mgr)
2019-09-22
julia> apply(rd"(2m - 1d)@WEEKEND[PBD]", Date(2019,7,23), cal_mgr)
2019-09-20
```
"""
@auto_hash_equals struct CalendarAdj{R <: RDate, S <: HolidayRoundingConvention} <: RDate
    calendar_names::Vector{String}
    part::R
    rounding::S

    CalendarAdj(calendar_names, part::R, rounding::S) where {R <: RDate, S <: HolidayRoundingConvention} = new{R, S}(calendar_names, part, rounding)
    CalendarAdj(calendar_names::String, part::R, rounding::S) where {R<:RDate, S <: HolidayRoundingConvention} = new{R,S}(split(calendar_names, "|"), part, rounding)
end

function apply(rdate::CalendarAdj, date::Dates.Date, cal_mgr::CalendarManager)
    base_date = apply(rdate.part, date, cal_mgr)
    cal = calendar(cal_mgr, rdate.calendar_names)
    apply(rdate.rounding, base_date, cal)
end
multiply(rdate::CalendarAdj, count::Integer) = CalendarAdj(rdate.calendar_names, multiply(rdate.part, count), rdate.rounding)

Base.:-(x::CalendarAdj) = CalendarAdj(x.calendar_names, -x.part, x.rounding)
Base.show(io::IO, rdate::CalendarAdj) = print(io, "($(rdate.part))@$(join(rdate.calendar_names, "|"))[$(rdate.rounding)]")

"""
    Next(parts, inclusive::Bool = false)

Next is a mechanism through which we can find the next closest date in the future, given a list of
rdates to apply. We can choose whether today is also deemed a valid date.

This is commonly used in conjunction with rdates which don't necessarily always give a date in the
future, such as asking for the next Easter from today.

### Examples
```julia-repl
julia> RDates.Next([RDates.Easter(0), RDates.Easter(1)]) + Date(2019,1,1)
2019-04-21
julia> rd"Next(0E,1E)" + Date(2019,1,1)
2019-04-21
julia> RDates.Next([RDates.Easter(0), RDates.Easter(1)]) + Date(2019,4,21)
2020-04-12
julia> RDates.Next([RDates.Easter(0), RDates.Easter(1)], true) + Date(2019,4,21)
2019-04-21
julia> rd"Next!(0E,1E)" + Date(2019,4,21)
2019-04-21
```

!!! note
    The negation of `Next` will actually produce a `Previous`.

    ```julia-repl
    julia> -rd"Next(1d,2d)"
    Previous(-1d, -2d)
    julia> -3 * rd"Next(1d,2d)"
    Previous(-3d, -6d)
    ```

!!! warning
    While `Next` is a powerful operator, it does require application of every rdate
    every time, so can be expensive.

    When combining with ranges, it can often be useful to use an appropriate pivot
    point to start from instead.
"""
@auto_hash_equals struct Next <: RDate
    parts::Vector{RDate}
    inclusive::Bool

    Next(parts, inclusive::Bool = false) = new(parts, inclusive)
end


"""
    Previous(parts, inclusive::Bool = false)

Previous is a mechanism through which we can find the next closest date in the past, given a list of
rdates to apply. We can choose whether today is also deemed a valid date.

This is commonly used in conjunction with rdates which don't necessarily always give a date in the
future, such as asking for the previous Easter from today.

### Examples
```julia-repl
julia> RDates.Previous([RDates.Easter(0), RDates.Easter(-1)]) + Date(2019,12,31)
2019-04-21
julia> rd"Previous(0E,-1E)" + Date(2019,12,31)
2019-04-21
julia> RDates.Previous([RDates.Easter(0), RDates.Easter(-1)]) + Date(2019,4,21)
2018-04-01
julia> RDates.Previous([RDates.Easter(0), RDates.Easter(-1)], true) + Date(2019,4,21)
2019-04-21
julia> rd"Previous!(0E,-1E)" + Date(2019,4,21)
2019-04-21
```

!!! note
    The negation of `Previous` will actually produce a `Next`.

    ```julia-repl
    julia> -rd"Previous(-1d,-2d)"
    Next(1d, 2d)
    julia> -3 * rd"Previous(-1d,-2d)"
    Next(3d, 6d)
    ```


!!! warning
    While `Previous` is a powerful operator, it does require application of every rdate
    every time, so can be expensive.

    When combining with ranges, it can often be useful to use an appropriate pivot
    point to start from instead.
"""
@auto_hash_equals struct Previous <: RDate
    parts::Vector{RDate}
    inclusive::Bool

    Previous(parts, inclusive::Bool = false) = new(parts, inclusive)
end

function apply(rdate::Next, date::Dates.Date, cal_mgr::CalendarManager)
    dates = map(part -> apply(part, date, cal_mgr), rdate.parts)
    op = rdate.inclusive ? Base.:>= : Base.:>
    dates = [d for d in dates if op(d, date)]
    length(dates) > 0 || error("$rdate failed to apply to $date")
    min(dates...)
end

function apply(rdate::Previous, date::Dates.Date, cal_mgr::CalendarManager)
    dates = map(part -> apply(part, date, cal_mgr), rdate.parts)
    op = rdate.inclusive ? Base.:<= : Base.:<
    dates = [d for d in dates if op(d, date)]
    length(dates) > 0 || error("$rdate failed to apply to $date")
    max(dates...)
end

function multiply(rdate::Next, count::Integer)
    method = count >= 0 ? Next : Previous
    method(map(x -> multiply(x, count), rdate.parts), rdate.inclusive)
end

function multiply(rdate::Previous, count::Integer)
    method = count >= 0 ? Previous : Next
    method(map(x -> multiply(x, count), rdate.parts), rdate.inclusive)
end

Base.:-(rdate::Next) = Previous(map(-, rdate.parts), rdate.inclusive)
Base.:-(rdate::Previous) = Next(map(-, rdate.parts), rdate.inclusive)

function Base.show(io::IO, rdate::Next)
    incsign = rdate.inclusive ? "!" : ""
    print(io, "Next$incsign(")
    for (i,part) in enumerate(rdate.parts)
        show(io, part)
        if i < length(rdate.parts)
            print(io, ", ")
        end
    end
    print(io, ")")
end


function Base.show(io::IO, rdate::Previous)
    incsign = rdate.inclusive ? "!" : ""
    print(io, "Previous$incsign(")
    for (i,part) in enumerate(rdate.parts)
        show(io, part)
        if i < length(rdate.parts)
            print(io, ", ")
        end
    end
    print(io, ")")
end
