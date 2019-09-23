import Dates
using Compat

@compat abstract type RDate end
@compat abstract type CalendarManager end
@compat abstract type Calendar end
@compat abstract type HolidayRoundingConvention end

is_holiday(x::Calendar, ::Dates.Date) = error("$(typeof(x)) does not support is_holiday")
calendar(x::CalendarManager, ::String)::Calendar = error("$(typeof(x)) does not support calendar")
apply(rd::RDate, ::Dates.Date, ::CalendarManager)::Dates.Date = error("$(typeof(rd)) does not support date apply")
Base.:-(x::RDate)::RDate = error("$(typeof(x)) does not support negation")
apply(x::HolidayRoundingConvention, ::Dates.Date, ::Calendar)::Dates.Date = error("$(typeof(x)) does not support apply")
