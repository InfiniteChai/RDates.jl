import Dates

"""
    NullCalendar()

A holiday calendar for which there is never a holiday. *sigh*
"""
struct NullCalendar <: Calendar end

is_holiday(::NullCalendar, ::Dates.Date) = false
holidays(::NullCalendar, ::Dates.Date, ::Dates.Date) = Set{Dates.Date}()

"""
    WeekendCalendar()

A calendar which will mark every Saturday and Sunday as a holiday
"""
struct WeekendCalendar <: Calendar end

function is_holiday(::WeekendCalendar, date::Dates.Date)
    signbit(5 - Dates.dayofweek(date))
end

function holidays(::WeekendCalendar, from::Dates.Date, to::Dates.Date)
    sats = Set(range(from + rd"1SAT!", to, rd"1w"))
    suns = Set(range(from + rd"1SUN!", to, rd"1w"))
    union(sats, suns)
end

"""
    CachedCalendar(cal::Calendar)

Creating a wrapping calendar that will cache the holidays lazily as retrieved
for a given year, rather than loading them in one go.
"""
struct CachedCalendar <: Calendar
    calendar::Calendar
    cache::Dict{UInt16,Set{Dates.Date}}

    CachedCalendar(cal::Calendar) = new(cal, Dict())
end

Base.show(io::IO, mgr::CachedCalendar) = (print(io, "CachedCalendar("); show(io, mgr.calendar); print(io, ")"))


yearholidays(cal::CachedCalendar, year) = get!(cal.cache, UInt16(year)) do
    holidays(cal.calendar, Dates.Date(year,1,1), Dates.Date(year,12,31))
end

is_holiday(cal::CachedCalendar, date::Dates.Date) = date in yearholidays(cal, Dates.year(date))

function holidays(cal::CachedCalendar, from::Dates.Date, to::Dates.Date)
    hols = Set{Dates.Date}()
    for year in Dates.year(from):Dates.year(to)
        yearhols = yearholidays(cal, year)
        if Dates.year(from) == year || Dates.year(to) == year
            yearhols = Set{Dates.Date}([x for x in yearhols if x >= from && x <= to])
        end
        union!(hols, yearhols)
    end
    hols
end

"""
    JointCalendar(calendars::Vector{Calendar}) <: Calendar

A grouping of calendars, for which it is a holiday if it's marked as a holiday
for any of the underlying calendars.

By default addition of calendars will generate a joint calendar for you.
"""
struct JointCalendar <: Calendar
    calendars::Vector{Calendar}
end

function is_holiday(cal::JointCalendar, date::Dates.Date)
    foldl(
        (acc, val) -> acc || is_holiday(val, date),
        cal.calendars;
        init = false,
    )
end
function holidays(cal::JointCalendar, from::Dates.Date, to::Dates.Date)
    foldl((acc, val) -> union(acc, holidays(val, from, to)), cal.calendars; init=Set{Dates.Date}())
end

Base.:+(cal1::Calendar, cal2::Calendar) = JointCalendar([cal1, cal2])
Base.:+(cal1::Calendar, cal2::JointCalendar) =
    JointCalendar(vcat(cal1, cal2.calendars))
Base.:+(cal1::JointCalendar, cal2::Calendar) =
    JointCalendar(vcat(cal1.calendars, cal2))
Base.:+(cal1::JointCalendar, cal2::JointCalendar) =
    JointCalendar(vcat(cal1.calendars, cal2.calendars))

"""
    SimpleCalendarManager()
    SimpleCalendarManager(calendars::Dict{String, Calendar})

A basic calendar manager which just holds a reference to each underlying calendar, by name,
and will generate a joint calendar if multiple names are requested.

To set a calendar on this manager then use `setcalendar!`

```julia-repl
julia> mgr = SimpleCalendarManager()
julia> setcalendar!(mgr, "WEEKEND", WeekendCalendar())
WeekendCalendar()
```

If you want to set a cached wrapping of a calendar then use `setcachedcalendar!`


```julia-repl
julia> mgr = SimpleCalendarManager()
julia> setcachedcalendar!(mgr, "WEEKEND", WeekendCalendar())
CachedCalendar(WeekendCalendar())
```

### Examples
```julia-repl
julia> mgr = SimpleCalendarManager()
julia> setcalendar!(mgr, "WEEKEND", WeekendCalendar())
julia> is_holiday(calendar(mgr, ["WEEKEND"]), Date(2019,9,28))
true
```
"""
struct SimpleCalendarManager <: CalendarManager
    calendars::Dict{String,Calendar}
    SimpleCalendarManager(calendars) = new(calendars)
    SimpleCalendarManager() = new(Dict())
end
Base.show(io::IO, mgr::SimpleCalendarManager) = (print(io, "SimpleCalendarManager($(length(mgr.calendars)) calendars)"))

setcalendar!(mgr::SimpleCalendarManager, name::String, cal::Calendar) = (mgr.calendars[name] = cal;)
setcachedcalendar!(mgr::SimpleCalendarManager, name::String, cal::Calendar) = (mgr.calendars[name] = CachedCalendar(cal);)
setcachedcalendar!(mgr::SimpleCalendarManager, name::String, cal::CachedCalendar) = setcalendar!(mgr, name, cal)

function calendar(cal_mgr::SimpleCalendarManager, names::Vector)::Calendar
    if length(names) == 0
        NullCalendar()
    elseif length(names) == 1
        cal_mgr.calendars[names[1]]
    else
        foldl(
            (acc, val) -> acc + cal_mgr.calendars[val],
            names[2:end],
            cal_mgr.calendars[names[1]],
        )
    end
end

"""
    get_calendar_names(rdate::RDate)::Vector{String}

A helper method to get all of the calendar names that could potentially be requested by this rdate. This
mechanism can be used to mark the minimal set of calendars on which adjustments depend.
"""
get_calendar_names(::RDate) = Vector{String}()
get_calendar_names(rdate::Union{BizDays,CalendarAdj}) = rdate.calendar_names
get_calendar_names(rdate::Compound) = Base.foldl((val, acc) -> vcat(
        acc,
        get_calendar_names(val),
        rdate.parts,
        init = Vector{String}(),
    ))
get_calendar_names(rdate::Repeat) = get_calendar_names(rdate.part)
