
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
