import Dates

struct WeekendCalendar <: Calendar end

function is_holiday(::WeekendCalendar, date::Dates.Date)
    signbit(5 - Dates.dayofweek(date))
end

struct SimpleCalendarManager <: CalendarManager
    calendars::Dict{String, Calendar}
end

calendar(cal_mgr::SimpleCalendarManager, name::String) = cal_mgr.calendars[name]
