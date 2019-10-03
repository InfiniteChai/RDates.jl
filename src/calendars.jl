import Dates
import StaticArrays

"""
    NullCalendar() <: Calendar

A holiday calendar for which there is never a holiday. *sigh*
"""
struct NullCalendar <: Calendar end

is_holiday(::NullCalendar, ::Dates.Date) = false

"""
    WeekendCalendar() <: Calendar

A calendar which will mark every Saturday and Sunday as a holiday
"""
struct WeekendCalendar <: Calendar end

function is_holiday(::WeekendCalendar, date::Dates.Date)
    signbit(5 - Dates.dayofweek(date))
end

"""
    JointCalendar(calendars::Vector{Calendar}) <: Calendar

A grouping of calendars, for which it is a holiday if it's marked as a holiday
for any of the underlying calendars.

By default addition of calendars will generate a joint calendar for you.
"""
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

"""
    SimpleCalendarManager(calendars::Dict{String, Calendar}) <: Calendar

A basic calendar manager which just holds a reference to each underlying calendar, by name,
and will generate a joint calendar if multiple names are requested.
"""
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


"""
    get_calendar_names(rdate::RDate)::Vector{String}

A helper method to get all of the calendar names that could potentially be requested by this rdate. This
mechanism can be used to mark the minimal set of calendars on which adjustments depend.
"""
get_calendar_names(::RDate) = Vector{String}()
get_calendar_names(rdate::CalendarAdj) = [rdate.calendar_name]
get_calendar_names(rdate::RDateCompound) = Base.foldl((val,acc) -> vcat(acc, get_calendar_names(val), rdate.parts, init=Vector{String}()))
get_calendar_names(rdate::RDateRepeat) = get_calendar_names(rdate.part)
