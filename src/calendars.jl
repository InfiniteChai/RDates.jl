import Dates
import StaticArrays

struct NullCalendar <: Calendar end

is_holiday(::NullCalendar, ::Dates.Date) = false

struct WeekendCalendar <: Calendar end

function is_holiday(::WeekendCalendar, date::Dates.Date)
    signbit(5 - Dates.dayofweek(date))
end

struct JointCalendar{T} <: Calendar
    calendars::StaticArrays.SVector{T,Calendar}

    JointCalendar(calendars) = new{length(calendars)}(calendars)
end

function is_holiday(cal::JointCalendar, date::Dates.Date)
    foldl((acc, val) -> acc && is_holiday(val, date), cal.calendars; init = false)
end

Base.:+(cal1::Calendar, cal2::Calendar) = JointCalendar([cal1, cal2])
Base.:+(cal1::Calendar, cal2::JointCalendar) = JointCalendar(vcat(cal1, cal2.calendars))
Base.:+(cal1::JointCalendar, cal2::Calendar) = JointCalendar(vcat(cal1.calendars, cal2))
Base.:+(cal1::JointCalendar, cal2::JointCalendar) = JointCalendar(vcat(cal1.calendars, cal2.calendars))

struct SimpleCalendarManager <: CalendarManager
    calendars::Dict{String, Calendar}
end

function calendar(cal_mgr::SimpleCalendarManager, names)::Calendar
    if length(names) == 0
        NullCalendar()
    elseif length(names) == 1
        cal_mgr.calendars[names[1]]
    else
        foldl((acc, val) -> acc + cal_mgr.calendars[val], names[2:end], cal_mgr.calendars[names[1]])
    end
end


# Helper method to get the calendar names associated with a given rdate
get_calendar_names(::RDate) = Vector{String}()
get_calendar_names(rdate::CalendarAdj) = [rdate.calendar_name]
get_calendar_names(rdate::RDateCompound) = Base.foldl((val,acc) -> vcat(acc, get_calendar_names(val), rdate.parts, init=Vector{String}()))
get_calendar_names(rdate::RDateRepeat) = get_calendar_names(rdate.part)
