"""
    range(from::Date, rdate::RDate; inc_from=true, cal_mgr=nothing)
    range(from::Date, to::Date, rdate::RDate; inc_from=true, inc_to=true, cal_mgr=nothing)

The range provides a mechanism for iterating over a range of dates given a period. This can
provide a mechanism for getting an infinite range (from a given date) or appropriately
clipped.

```julia-repl
julia> collect(Iterators.take(range(Date(2017,1,25), rd"1d"), 3))
3-element Vector{Date}:
 2017-01-25
 2017-01-26
 2017-01-27
julia> collect(Iterators.take(range(Date(2017,1,25), rd"1d"; inc_from=false), 3))
3-element Vector{Date}:
 2017-01-26
 2017-01-27
 2017-01-28
julia> collect(range(Date(2019,4,17), Date(2019,4,22), rd"2d"))
3-element Vector{Date}:
 2019-04-17
 2019-04-19
 2019-04-21
```

Under the hoods, the range will `multiply` the period. Since non-periodic RDates will
always give back self when you multiply it allows us to set a reference point.
```julia-repl
julia> rd"1JAN2001+3m+3rd WED"
1JAN2001+3m[LDOM;PDOM]+3rd WED
julia> 3*rd"1JAN2001+3m+3rd WED"
1JAN2001+9m[LDOM;PDOM]+3rd WED
```

This provides the basic building blocks to come up with more complex functionality. For
example to get the next four [IMM dates](https://en.wikipedia.org/wiki/IMM_dates)

```julia-repl
julia> d = Date(2017,1,1)
julia> collect(Iterators.take(range(d, rd"1MAR+3m+3rd WED"), 4))
4-element Vector{Date}:
 2017-03-15
 2017-06-21
 2017-09-20
 2017-12-20
```
"""
struct RDateRange
    from::Dates.Date
    to::Union{Dates.Date, Nothing}
    period::RDate
    inc_from::Bool
    inc_to::Bool
    calendar_mgr::CalendarManager
end

function Base.iterate(iter::RDateRange, state=nothing)
    if state === nothing
        count = 0
        elem = apply(multiply(iter.period, count), iter.from, iter.calendar_mgr)
        while elem > iter.from
            count -= 1
            elem = apply(multiply(iter.period, count), iter.from, iter.calendar_mgr)
        end

        from_op = iter.inc_from ? Base.:< : Base.:<=
        while from_op(elem, iter.from)
            count += 1
            elem = apply(multiply(iter.period, count), iter.from, iter.calendar_mgr)
        end

        state = (elem, count)
    end
    elem, count = state
    op = iter.inc_to ? Base.:> : Base.:>=
    if iter.to !== nothing && op(elem,iter.to)
        return nothing
    end

    return (elem, (apply(multiply(iter.period, count+1), iter.from, iter.calendar_mgr), count+1))
end

Base.IteratorSize(::Type{RDateRange}) = Base.SizeUnknown()
Base.eltype(::Type{RDateRange}) = Dates.Date
function Base.range(from::Dates.Date, period::RDate; inc_from::Bool=true, cal_mgr::Union{CalendarManager,Nothing}=nothing)
    return RDateRange(from, nothing, period, inc_from, false, cal_mgr !== nothing ? cal_mgr : NullCalendarManager())
end

function Base.range(from::Dates.Date, to::Dates.Date, period::RDate; inc_from::Bool=true, inc_to::Bool=true, cal_mgr::Union{CalendarManager,Nothing}=nothing)
    return RDateRange(from, to, period, inc_from, inc_to, cal_mgr !== nothing ? cal_mgr : NullCalendarManager())
end
