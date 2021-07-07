import Dates

"""
    InvalidDayLDOM <: InvalidDayConvention

When the day calculated is invalid, move to the last day of the month
"""
struct InvalidDayLDOM <: InvalidDayConvention end
adjust(::InvalidDayLDOM, day, month, year) = Dates.Date(year, month, Dates.daysinmonth(year, month))
Base.show(io::IO, ::InvalidDayLDOM) = print(io, "LDOM")

"""
    InvalidDayFDONM <: InvalidDayConvention

When the day calculated is invalid, move to the first day of the next month
"""
struct InvalidDayFDONM <: InvalidDayConvention end
adjust(::InvalidDayFDONM, day, month, year) = month == 12 ? Dates.Date(year+1, 1, 1) : Dates.Date(year, month+1, 1)
Base.show(io::IO, ::InvalidDayFDONM) = print(io, "FDONM")

"""
    InvalidDayNDONM <: InvalidDayConvention

When the day calculated is invalid, move to the nth day of the next month where
n is the number of days past the last day of the month
"""
struct InvalidDayNDONM <: InvalidDayConvention end
function adjust(::InvalidDayNDONM, day, month, year)
    dayδ = day - Dates.daysinmonth(year, month)
    return month == 12 ? Dates.Date(year+1, 1, dayδ) : Dates.Date(year, month+1, dayδ)
end
Base.show(io::IO, ::InvalidDayNDONM) = print(io, "NDONM")

const INVALID_DAY_MAPPINGS = Dict(
    "LDOM" => InvalidDayLDOM(),
    "FDONM" => InvalidDayFDONM(),
    "NDONM" => InvalidDayNDONM()
)
