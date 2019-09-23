import StaticArrays

struct RDateCompound{T} <: RDate
    parts::StaticArrays.SVector{T,RDate}

    RDateCompound(parts) = new{length(parts)}(parts)
end

apply(rdate::RDateCompound, date::Dates.Date, cal_mgr::CalendarManager) = Base.foldl((x,y) -> apply(y, x, cal_mgr), rdate.parts, init=date)
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

struct RDateRepeat <: RDate
    count::Int64
    part::RDate
end

apply(rdate::RDateRepeat, date::Dates.Date, cal_mgr::CalendarManager) = Base.foldl((x,y) -> apply(y, x, cal_mgr), fill(rdate.part, rdate.count), init=date)
Base.:-(rdate::RDateRepeat) = RDateRepeat(rdate.count, -rdate.part)
Base.show(io::IO, rdate::RDateRepeat) = (print(io, "$(rdate.count)*("), show(io, rdate.part), print(io,")"))

Base.:+(left::RDate, right::RDate) = combine(left, right)
Base.:-(left::RDate, right::RDate) = combine(left, -right)
Base.:*(count::Number, rdate::RDate) = rdate*count
Base.:*(rdate::RDate, count::Number) = RDateRepeat(count, rdate)

struct CalendarAdj{R <: RDate,S <: HolidayRoundingConvention} <: RDate
    calendar_name::String
    part::R
    rounding::S

    CalendarAdj(calendar_name, part::R, rounding::S) where {R <: RDate, S <: HolidayRoundingConvention} = new{R, S}(calendar_name, part, rounding)
end

function apply(rdate::CalendarAdj, date::Dates.Date, cal_mgr::CalendarManager)
    base_date = apply(rdate.part, date, cal_mgr)
    cal = calendar(cal_mgr, rdate.calendar_name)
    apply(rdate.rounding, base_date, cal)
end
