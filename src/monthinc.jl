import Dates
using AutoHashEquals

struct MonthIncrementPDOM <: MonthIncrementConvention end
adjust(::MonthIncrementPDOM, date::Dates.Date, new_month, new_year, cal_mgr::CalendarManager) = (new_year, new_month, Dates.day(date))
Base.show(io::IO, ::MonthIncrementPDOM) = print(io, "PDOM")

@auto_hash_equals struct MonthIncrementPDOMEOM <: MonthIncrementConvention
    calendars::Union{Vector{String}, Nothing}

    MonthIncrementPDOMEOM() = new(nothing)
    MonthIncrementPDOMEOM(calendars) = new(calendars)
end

function adjust(mic::MonthIncrementPDOMEOM, date::Dates.Date, new_month, new_year, cal_mgr::CalendarManager)
    ldom = Dates.lastdayofmonth(date)
    cal = mic.calendars === nothing ? nothing : calendar(cal_mgr, mic.calendars)
    if cal !== nothing
        ldom = apply(HolidayRoundingPBD(), ldom, cal)
    end

    if ldom == date
        new_ldom = Dates.lastdayofmonth(Dates.Date(new_year, new_month))
        if cal !== nothing
            new_ldom = apply(HolidayRoundingPBD(), new_ldom, cal)
        end

        return Dates.yearmonthday(new_ldom)
    else
        return (new_year, new_month, Dates.day(date))
    end
end

Base.show(io::IO, mic::MonthIncrementPDOMEOM) = mic.calendars === nothing ? print(io, "PDOMEOM") : print(io, "PDOMEOM@$(join(mic.calendars, "|"))")

const MONTH_INCREMENT_MAPPINGS = Dict("PDOM" => MonthIncrementPDOM(), "PDOMEOM" => MonthIncrementPDOMEOM())
