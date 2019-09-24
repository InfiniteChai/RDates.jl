import Dates

struct WeekendCalendar <: Calendar end

function is_holiday(::WeekendCalendar, date::Dates.Date)
    signbit(5 - Dates.dayofweek(date))
end

struct SimpleCalendarManager <: CalendarManager
    calendars::Dict{String, Calendar}
end

calendar(cal_mgr::SimpleCalendarManager, name::String)::Calendar = cal_mgr.calendars[name]

# Helper method to get the calendar names associated with a given rdate
get_calendar_names(::RDate) = Vector{String}()
get_calendar_names(rdate::CalendarAdj) = [rdate.calendar_name]
get_calendar_names(rdate::RDateCompound) = Base.foldl((val,acc) -> vcat(acc, get_calendar_names(val), rdate.parts, init=Vector{String}()))
get_calendar_names(rdate::RDateRepeat) = get_calendar_names(rdate.part)
