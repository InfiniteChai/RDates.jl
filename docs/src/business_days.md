# Business Days

Up to now we have dealt with date operations that do not take into consideration one of the key features, holidays. Whether its working around weekends or the UK's bank holidays, operations involving holidays (or equivalently *business days*) is essential.

As such the RDate package provides the construct to allow you to work with holiday calendars, without tying you to a specific implementation.

!!! note

    `RDates` will never provide an explicit implementation of the calendar system, but do check out
    [HolidayCalendars](https://github.com/InfiniteChai/HolidayCalendars.jl) which will get released soon
    which builds rule-based calendar systems.

Before we walk through how this is integrated into the RDate language, we'll look at how calendars are modelled.

## Calendars

A calendar defines whether a given day is a holiday. To implement a calendar you need to inherit from `RDates.Calendar` and define the following methods.

```@docs
RDates.is_holiday
RDates.holidays
```

Calendars also come with a number of helpful wrapper methods

```@docs
RDates.holidaycount
RDates.bizdaycount
```

RDate provides some primitive calendar implementations to get started with
```@docs
RDates.NullCalendar
RDates.WeekendCalendar
RDates.JointCalendar
RDates.CachedCalendar
```

## Calendar Manager

To access calendars within the relative date library, we use a calendar manager. It provides the interface to access calendars based on their name, a string identifier.

A calendar manager must inherit from `RDates.CalendarManager` and implement the following
```@docs
calendar(::RDates.CalendarManager, ::Vector)
```

RDates provides some primitive calendar manager implementations to get started with
```@docs
RDates.NullCalendarManager
RDates.SimpleCalendarManager
```

When you just add a `Date` and an `RDate` then we'll use the `NullCalendarManager()` by
default. To pass a calendar manager to the rdate when it's been applied, use the `apply` function.
```@docs
RDates.apply
```

## Calendar Adjustments

Now that we have a way for checking whether a given day is a holiday and can use your calendar manager, let's introduce calendar adjustments.

These allow us to apply a holiday calendar adjustment, after a base rdate has been applied. To support this we need to introduce the concept of *Holiday Rounding*.

### Holiday Rounding Convention
The holiday rounding convention provides the details on what to do if we fall on a holiday.

```@docs
RDates.HolidayRoundingNBD
RDates.HolidayRoundingPBD
RDates.HolidayRoundingNBDSM
RDates.HolidayRoundingPBDSM
RDates.HolidayRoundingNR
RDates.HolidayRoundingNearest
```

Now we have everything we need to define calendar adjustments and business days

```@docs
RDates.CalendarAdj
RDates.BizDays
```
