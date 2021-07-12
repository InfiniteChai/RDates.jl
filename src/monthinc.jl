import Dates
using AutoHashEquals

"""
    MonthIncrementPDOM()

When incrementing by months (or years) then preserve the day of month from
originally requested. Uses the "PDOM" shorthand
"""
struct MonthIncrementPDOM <: MonthIncrementConvention end
adjust(::MonthIncrementPDOM, date::Dates.Date, new_month, new_year, cal_mgr::CalendarManager) = (new_year, new_month, Dates.day(date))
Base.show(io::IO, ::MonthIncrementPDOM) = print(io, "PDOM")


"""
    MonthIncrementPDOMEOM()
    MonthIncrementPDOMEOM(calendars)

When incrementing by months (or years) then preserve the day of month from
originally requested, unless it's the last day of the month then maintain that.
Uses the "PDOMEOM" short hand.

To preserve the last business day of the month, then you can pass calendars as
well.
"""
@auto_hash_equals struct MonthIncrementPDOMEOM <: MonthIncrementConvention
    calendars::Union{Vector{String}, Nothing}

    MonthIncrementPDOMEOM() = new(nothing)
    MonthIncrementPDOMEOM(calendars) = new(calendars)
    MonthIncrementPDOMEOM(calendars::String) = new(split(calendars, "|"))
end

function adjust(mic::MonthIncrementPDOMEOM, date::Dates.Date, new_month, new_year, cal_mgr::CalendarManager)
    ldom_rdate = LDOM(mic.calendars)
    ldom = apply(ldom_rdate, date, cal_mgr)

    if ldom == date
        new_ldom = apply(ldom_rdate, Dates.Date(new_year, new_month), cal_mgr)
        return Dates.yearmonthday(new_ldom)
    else
        return (new_year, new_month, Dates.day(date))
    end
end

Base.show(io::IO, mic::MonthIncrementPDOMEOM) = mic.calendars === nothing ? print(io, "PDOMEOM") : print(io, "PDOMEOM@$(join(mic.calendars, "|"))")

const MONTH_INCREMENT_MAPPINGS = Dict(
    "PDOM" => MonthIncrementPDOM(),
    "PDOMEOM" => MonthIncrementPDOMEOM()
)
