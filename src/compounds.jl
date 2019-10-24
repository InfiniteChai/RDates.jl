using AutoHashEquals

@auto_hash_equals struct RDateCompound <: RDate
    parts::Vector{RDate}
end

apply(rdate::RDateCompound, date::Dates.Date, cal_mgr::CalendarManager) = Base.foldl((x,y) -> apply(y, x, cal_mgr), rdate.parts, init=date)
multiply_no_roll(rdate::RDateCompound, count::Integer) = RDateCompound(map(x -> multiply_no_roll(x, count), rdate.parts))
Base.:-(rdate::RDateCompound) = RDateCompound(map(-, rdate.parts))
Base.:+(x::RDateCompound, y::RDate) = RDateCompound(vcat(x.parts, y))
Base.:+(x::RDate, y::RDateCompound) = RDateCompound(vcat(x, y.parts))
combine(left::RDate, right::RDate) = RDateCompound([left,right])
function Base.show(io::IO, rdate::RDateCompound)
    for (i,part) in enumerate(rdate.parts)
        if i > 1 print(io, "+") end
        show(io, part)
    end
end

@auto_hash_equals struct RDateRepeat <: RDate
    count::Int64
    part::RDate
end

apply(rdate::RDateRepeat, date::Dates.Date, cal_mgr::CalendarManager) = Base.foldl((x,y) -> apply(y, x, cal_mgr), fill(rdate.part, rdate.count), init=date)
multiply_no_roll(rdate::RDateRepeat, count::Integer) = RDateRepeat(rdate.count, multiply_no_roll(rdate.part, count))
Base.:-(rdate::RDateRepeat) = RDateRepeat(rdate.count, -rdate.part)
Base.show(io::IO, rdate::RDateRepeat) = (print(io, "$(rdate.count)*roll("), show(io, rdate.part), print(io,")"))

Base.:+(left::RDate, right::RDate) = combine(left, right)
Base.:-(left::RDate, right::RDate) = combine(left, -right)
multiply_roll(rdate::RDate, count::Integer) = count >= 0 ? RDateRepeat(count, rdate) : RDateRepeat(-count, -rdate)

@auto_hash_equals struct CalendarAdj{R <: RDate, S <: HolidayRoundingConvention} <: RDate
    calendar_names::Vector{String}
    part::R
    rounding::S

    CalendarAdj(calendar_names, part::R, rounding::S) where {R <: RDate, S <: HolidayRoundingConvention} = new{R, S}(calendar_names, part, rounding)
end

function apply(rdate::CalendarAdj, date::Dates.Date, cal_mgr::CalendarManager)
    base_date = apply(rdate.part, date, cal_mgr)
    cal = calendar(cal_mgr, rdate.calendar_names)
    apply(rdate.rounding, base_date, cal)
end
multiply_no_roll(rdate::CalendarAdj, count::Integer) = CalendarAdj(rdate.calendar_names, multiply_no_roll(rdate.part, count), rdate.rounding)

Base.:-(x::CalendarAdj) = CalendarAdj(x.calendar_names, -x.part, x.rounding)
