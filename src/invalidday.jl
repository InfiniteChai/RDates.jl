import Dates

struct InvalidDayLDOM <: InvalidDayConvention end
adjust(::InvalidDayLDOM, day, month, year) = Dates.Date(year, month, Dates.daysinmonth(year, month))
Base.show(io::IO, ::InvalidDayLDOM) = print(io, "LDOM")

struct InvalidDayFDONM <: InvalidDayConvention end
adjust(::InvalidDayFDONM, day, month, year) = month == 12 ? Dates.Date(year+1, 1, 1) : Dates.Date(year, month+1, 1)
Base.show(io::IO, ::InvalidDayFDONM) = print(io, "FDONM")

struct InvalidDayNDONM <: InvalidDayConvention end
function adjust(::InvalidDayNDONM, day, month, year)
    dayδ = day - Dates.daysinmonth(year, month)
    return month == 12 ? Dates.Date(year+1, 1, dayδ) : Dates.Date(year, month+1, dayδ)
end
Base.show(io::IO, ::InvalidDayNDONM) = print(io, "NDONM")

const INVALID_DAY_MAPPINGS = Dict("LDOM" => InvalidDayLDOM(), "FDONM" => InvalidDayFDONM(), "NDONM" => InvalidDayNDONM())
