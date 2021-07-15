import Dates

"""
    NullCalendar()

A holiday calendar for which there is never a holiday. *sigh*
"""
struct NullCalendar <: Calendar end

is_holiday(::NullCalendar, ::Dates.Date) = false
holidays(::NullCalendar, from::Dates.Date, to::Dates.Date) = Base.repeat([false], (to - from).value + 1)

"""
    WeekendCalendar()

A calendar which will mark every Saturday and Sunday as a holiday
"""
struct WeekendCalendar <: Calendar end

function is_holiday(::WeekendCalendar, date::Dates.Date)
    signbit(5 - Dates.dayofweek(date))
end

function holidays(::WeekendCalendar, from::Dates.Date, to::Dates.Date)
    dow = Dates.dayofweek(from)
    days = (to - from).value + 1


    hols = Base.repeat([false], days)
    satstart = dow == 7 ? 7 : 7 - dow
    sunstart = 8 - dow
    for i in Iterators.flatten([satstart:7:days, sunstart:7:days])
        @inbounds hols[i] = true
    end
    hols
end


mutable struct CalendarCache
    bdays::Vector{Bool}
    bdayscounter::Vector{UInt32}
    dtmin::Dates.Date
    dtmax::Dates.Date
    initialised::Bool

    CalendarCache() = new([], [], Dates.Date(1900,1,1), Dates.Date(1900,1,1), false)
end

function needsupdate(cache::CalendarCache, d0::Dates.Date, d1::Dates.Date)
    !cache.initialised || d0 < cache.dtmin || d1 > cache.dtmax
end


"""
    CachedCalendar(cal::Calendar)

Creating a wrapping calendar that will cache the holidays lazily as retrieved
for a given year, rather than loading them in one go.
"""
struct CachedCalendar <: Calendar
    calendar::Calendar
    cache::CalendarCache
    period::UInt8
    CachedCalendar(cal::Calendar) = new(cal, CalendarCache(), 10)
end

Base.show(io::IO, mgr::CachedCalendar) = (print(io, "CachedCalendar("); show(io, mgr.calendar); print(io, ")"))


function updatecache!(cal::CachedCalendar, d0::Dates.Date, d1::Dates.Date)
    needsupdate(cal.cache, d0, d1) || return
    if cal.cache.initialised
        if d0 < cal.cache.dtmin
            days = (cal.cache.dtmin-d0).value
            bdays = holidays(cal.calendar, d0, cal.cache.dtmin-Dates.Day(1))
            cal.cache.bdays = vcat(bdays, cal.cache.bdays)
            counters = Base.sum(bdays) .+ cal.cache.bdayscounter

            lcounters = Vector{UInt32}(undef, days)
            lcounters[1] = UInt32(bdays[1])
            for i in 2:days
                @inbounds lcounters[i] = lcounters[i-1] + bdays[i]
            end
            cal.cache.bdayscounter = vcat(lcounters, counters)
            cal.cache.dtmin = d0
        end

        if d1 > cal.cache.dtmax
            days = (d1-cal.cache.dtmax).value
            bdays = holidays(cal.calendar, cal.cache.dtmax+Dates.Day(1), d1)
            cal.cache.bdays = vcat(cal.cache.bdays, bdays)
            rcounters = Vector{UInt32}(undef, days)
            rcounters[1] = cal.cache.bdayscounter[end] + UInt32(bdays[1])
            for i in 2:days
                @inbounds rcounters[i] = rcounters[i-1] + bdays[i]
            end
            cal.cache.bdayscounter = vcat(cal.cache.bdayscounter, rcounters)
            cal.cache.dtmax = d1
        end
    else
        days = (d1-d0).value + 1
        cal.cache.bdays = holidays(cal.calendar, d0, d1)
        cal.cache.bdayscounter = Vector{UInt32}(undef, days)
        cal.cache.bdayscounter[1] = UInt32(cal.cache.bdays[1])
        for i in 2:days
            @inbounds cal.cache.bdayscounter[i] = cal.cache.bdayscounter[i-1] + cal.cache.bdays[i]
        end
        cal.cache.dtmin = d0
        cal.cache.dtmax = d1
        cal.cache.initialised = true
    end
end

function is_holiday(cal::CachedCalendar, date::Dates.Date)
    if needsupdate(cal.cache, date, date)
        d0 = Dates.Date(cal.period*div(Dates.year(date), cal.period), 1, 1)
        d1 = Dates.Date(cal.period*(1+div(Dates.year(date), cal.period)), 12, 31)
        updatecache!(cal, d0, d1)
    end
    t0 = (date-cal.cache.dtmin).value + 1
    cal.cache.bdays[t0]
end

function holidaycount(cal::CachedCalendar, from::Dates.Date, to::Dates.Date)
    if needsupdate(cal.cache, from, to)
        d0 = Dates.Date(cal.period*div(Dates.year(from), cal.period), 1, 1)
        d1 = Dates.Date(cal.period*(1+div(Dates.year(to), cal.period)), 12, 31)
        updatecache!(cal, d0, d1)
    end

    t0 = (from-cal.cache.dtmin).value + 1
    t1 = (to-from).value

    Int(cal.cache.bdayscounter[t1+t0] - cal.cache.bdayscounter[t0] + cal.cache.bdays[t0])
end

function holidays(cal::CachedCalendar, from::Dates.Date, to::Dates.Date)
    if needsupdate(cal.cache, from, to)
        d0 = Dates.Date(cal.period*div(Dates.year(from), cal.period), 1, 1)
        d1 = Dates.Date(cal.period*(1+div(Dates.year(to), cal.period)), 12, 31)
        updatecache!(cal, d0, d1)
    end
    t0 = (from-cal.cache.dtmin).value + 1
    t1 = (to-from).value
    cal.cache.bdays[t0:t0+t1]
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
    hols = Base.repeat([false], (to-from).value+1)
    for subcal in cal.calendars
        hols = hols .| holidays(subcal, from, to)
    end
    hols
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
