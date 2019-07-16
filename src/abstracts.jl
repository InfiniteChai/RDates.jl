import Dates
using Compat

@compat abstract type RDate end

Base.:+(x::RDate, y::Dates.Date) = error("$(typeof(x)) does not support date addition")
Base.:+(x::Dates.Date, y::RDate) = y + x
Base.:-(x::RDate) = error("$(typeof(x)) does not support negation")
