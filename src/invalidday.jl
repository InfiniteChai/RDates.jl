module InvalidDay

using Compat
import Dates

@compat abstract type InvalidDayConvention end
adjust(idm::InvalidDayConvention, day, month, year) = error("Needs implementation")

struct LastDayOfMonth <: InvalidDayConvention end
adjust(idm::LastDayOfMonth, day, month, year) = Dates.Date(year, month, Dates.daysinmonth(year, month))
Base.show(io::IO, ::LastDayOfMonth) = print(io, "LDOM")

struct FirstDayOfNextMonth <: InvalidDayConvention end
adjust(idm::FirstDayOfNextMonth, day, month, year) = month == 12 ? Dates.Date(year+1, 1, 1) : Dates.Date(year, month+1, 1)
Base.show(io::IO, ::FirstDayOfNextMonth) = print(io, "FDONM")

struct NthDayOfNextMonth <: InvalidDayConvention end
function adjust(idm::NthDayOfNextMonth, day, month, year)
    dayδ = day - Dates.daysinmonth(year, month)
    return month == 12 ? Dates.Date(year+1, 1, dayδ) : Dates.Date(year, month+1, dayδ)
end
Base.show(io::IO, ::NthDayOfNextMonth) = print(io, "NDONM")

const LDOM = LastDayOfMonth()
const FDONM = FirstDayOfNextMonth()
const NDONM = NthDayOfNextMonth()

const MAPPINGS = Dict("LDOM" => LDOM, "FDONM" => FDONM, "NDONM" => NDONM)

end # module InvDay
