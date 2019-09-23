import Dates
using Compat

@compat abstract type RDate end
# Calendars
@compat abstract type CalendarManager end
@compat abstract type Calendar end
# Conventions
@compat abstract type HolidayRoundingConvention end
@compat abstract type InvalidDayConvention end
@compat abstract type MonthIncrementConvention end

is_holiday(x::Calendar, ::Dates.Date) = error("$(typeof(x)) does not support is_holiday")
calendar(x::CalendarManager, ::String)::Calendar = error("$(typeof(x)) does not support calendar")

apply(rd::RDate, ::Dates.Date, ::CalendarManager)::Dates.Date = error("$(typeof(rd)) does not support date apply")
Base.:-(x::RDate)::RDate = error("$(typeof(x)) does not support negation")

apply(x::HolidayRoundingConvention, ::Dates.Date, ::Calendar)::Dates.Date = error("$(typeof(x)) does not support apply")
adjust(x::InvalidDayConvention, day, month, year) = error("$(typeof(x)) does not support adjust")
adjust(x::MonthIncrementConvention, day, month, year, new_month, new_year) = error("$(typeof(x)) does not support adjust")
