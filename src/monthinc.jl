import Dates


struct MonthIncrementPDOM <: MonthIncrementConvention end
adjust(::MonthIncrementPDOM, day, month, year, new_month, new_year) = (new_year, new_month, day)
Base.show(io::IO, ::MonthIncrementPDOM) = print(io, "PDOM")

struct MonthIncrementPDOMEOM <: MonthIncrementConvention end
function adjust(::MonthIncrementPDOMEOM, day, month, year, new_month, new_year)
    ld = Dates.daysinmonth(year, month)
    return (new_year, new_month, day == ld ? Dates.daysinmonth(new_year, new_month) : day)
end
Base.show(io::IO, ::MonthIncrementPDOMEOM) = print(io, "PDOMEOM")

const MONTH_INCREMENT_MAPPINGS = Dict("PDOM" => MonthIncrementPDOM(), "PDOMEOM" => MonthIncrementPDOMEOM())
