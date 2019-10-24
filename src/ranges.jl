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
        elem = apply(multiply_no_roll(iter.period, count), iter.from, iter.calendar_mgr)
        while elem > iter.from
            count -= 1
            elem = apply(multiply_no_roll(iter.period, count), iter.from, iter.calendar_mgr)
        end

        from_op = iter.inc_from ? Base.:< : Base.:<=
        while from_op(elem, iter.from)
            count += 1
            elem = apply(multiply_no_roll(iter.period, count), iter.from, iter.calendar_mgr)
        end

        state = (elem, count)
    end
    elem, count = state
    op = iter.inc_to ? Base.:> : Base.:>=
    if iter.to !== nothing && op(elem,iter.to)
        return nothing
    end

    return (elem, (apply(multiply_no_roll(iter.period, count+1), iter.from, iter.calendar_mgr), count+1))
end

Base.IteratorSize(::Type{RDateRange}) = Base.SizeUnknown()
Base.eltype(::Type{RDateRange}) = Dates.Date
function Base.range(from::Dates.Date, period::RDate; inc_from::Bool=true, inc_to::Bool=true, cal_mgr::Union{CalendarManager,Nothing}=nothing)
    return RDateRange(from, nothing, period, inc_from, inc_to, cal_mgr !== nothing ? cal_mgr : calendar_mgr)
end

function Base.range(from::Dates.Date, to::Dates.Date, period::RDate; inc_from::Bool=true, inc_to::Bool=true, cal_mgr::Union{CalendarManager,Nothing}=nothing)
    return RDateRange(from, to, period, inc_from, inc_to, cal_mgr !== nothing ? cal_mgr : calendar_mgr)
end
