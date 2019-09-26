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

struct NullCalendarManager <: CalendarManager end

is_holiday(x::Calendar, ::Dates.Date) = error("$(typeof(x)) does not support is_holiday")
calendar(x::CalendarManager, names)::Calendar = error("$(typeof(x)) does not support calendar")

apply(rd::RDate, ::Dates.Date, ::CalendarManager)::Dates.Date = error("$(typeof(rd)) does not support date apply")
apply(rd::RDate, date::Dates.Date) = apply(rd, date, NullCalendarManager())

calendar_mgr = NullCalendarManager()
function with_cal_mgr(f::Function, cal_mgr::CalendarManager)
    global calendar_mgr
    current_cal_mgr = calendar_mgr
    calendar_mgr = cal_mgr
    try
        f()
    finally
        calendar_mgr = current_cal_mgr
    end
end

Base.:+(rd::RDate, date::Dates.Date) = apply(rd, date, calendar_mgr)
Base.:+(date::Dates.Date, rd::RDate) = apply(rd, date, calendar_mgr)
Base.:-(date::Dates.Date, rd::RDate) = apply(-rd, date)
Base.:-(x::RDate)::RDate = error("$(typeof(x)) does not support negation")

apply(x::HolidayRoundingConvention, ::Dates.Date, ::Calendar)::Dates.Date = error("$(typeof(x)) does not support apply")
adjust(x::InvalidDayConvention, day, month, year) = error("$(typeof(x)) does not support adjust")
adjust(x::MonthIncrementConvention, day, month, year, new_month, new_year) = error("$(typeof(x)) does not support adjust")
