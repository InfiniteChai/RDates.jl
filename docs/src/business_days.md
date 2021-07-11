# Overview

Up to now we have dealt with date operations that do not take into consideration one of the key features, holidays. Whether its working around weekends or the UK's bank holidays, operations involving holidays (or equivalently *business days*) is essential.

As such the RDate package provides the construct to allow you to work with holiday calendars, without tying you to a specific implementation.

!!! note

    It is currently not within the scope of RDates to build a calendar system, but I do envisage this as the next step as the essential components for it are provided.

Before we walk through how this is integrated into the RDate language, we'll look at how calendars are modelled.

## Calendars

A calendar defines whether a given day is a holiday. To implement a calendar you need to inherit from `RDates.Calendar` and define the method `is_holiday(x::Calendar, ::Dates.Date)::Bool`.

We provide basic calendar implementations to support addition and weekends.

## Calendar Manager

To access calendars within the relative date library, we use a calendar manager. It provides the interface to access calendars based on their name, a string identifier.

We provide a basic implementation called `SimpleCalendarManager` that will wrap up basic calendars in a hashmap.

```julia
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> is_holiday(calendar(cal_mgr, ["WEEKEND"]), Date(2019,9,28))
true
```

You can pass the calendar manager as an optional argument to `apply`

```julia
julia> apply(rd"1b@WEEKEND", Date(2019,1,1), cal_mgr)
2019-01-02
```

## Calendar Adjustments

Now that we have a way for checking whether a given day is a holiday and can use your calendar manager, let's introduce calendar adjustments.

These allow us to apply a holiday calendar adjustment, after a base rdate has been applied. To support this we need to introduce the concept of *Holiday Rounding*.

#### Holiday Rounding Convention
The holiday rounding convention provides the details on what to do if we fall on a holiday.

- **Next Business Day** or **NBD** means to move forward to the next day that is not a holiday.
- **Previous Business Day** or **PBD** means to move bacwards to the last day that was not a holiday.
- **Next Business Day Same Month** or **NBDSM** means to apply *Next Business Day* unless the day found is not in the same month as where we started, then instead apply *Previous Business Day*.
- **Previous Business Day Same Month** or **PBDSM** means to apply *Previous Business Day* unless the day found is not in the same month as where we started, then instead apply *Next Business Day*.
- **No Rounding** or **NR** means to apply *No Rounding* and give back the date provided.
- **Nearest** or **NEAR** means to move towards the nearest business day, with the next one
winning in a tie. This is commonly used for US bank holidays.

An adjustment is specified using the `@` symbol, followed by a `|` delimited set of calendar names. The holiday rounding convention is then provided in its short form in square brackets afterwards.

All calendar names must only contain characters `a-z`, `A-Z`, `0-9`, `-`, ` ` or `/`.

```julia
julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
julia> cal_mgr = RDates.SimpleCalendarManager(cals)
julia> apply(rd"1d", Date(2019,9,27), cal_mgr)
2019-09-28
julia> apply(rd"1d@WEEKEND[NBD]", Date(2019,9,27), cal_mgr)
2019-09-30
julia> apply(rd"2m - 1d", Date(2019,7,23), cal_mgr)
2019-09-22
julia> apply(rd"(2m - 1d)@WEEKEND[PBD]", Date(2019,7,23), cal_mgr)
2019-09-20
```

## Business Days
It can also be handy to work in business days at times, rather than calendar days. A holiday rounding convention is automatically selected, with a non-negative increment implying *Next Business Day* and a negative increment implying *Previous Business Day*.

!!! note

    For the zero increment operator `0b@CALENDAR` we select *Next Business Day*. However it's negation with `-0b@CALENDAR` will switch to *Previous Business Day*.

    ```julia
    julia> cals = Dict("WEEKEND" => RDates.WeekendCalendar())
    julia> cal_mgr = RDates.SimpleCalendarManager(cals)
    julia> apply(rd"0b@WEEKEND", Date(2019,9,28), cal_mgr)
    2019-09-30
    julia> apply(rd"-0b@WEEKEND", Date(2019,9,28), cal_mgr)
    2019-09-27
    julia> apply(rd"10b@WEEKEND", Date(2019,9,27), cal_mgr)
    2019-10-11
    ```
