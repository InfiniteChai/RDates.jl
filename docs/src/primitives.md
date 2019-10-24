# Primitives

RDates is designed to allow complex date operations to be completed using basic primitive types. Each of these primitive types and operations are explained in more detail in subsequent sections.

We now go through each of the primitive types, from which we can combine together using compounding operations.

## Days
Provides us with the ability to add or subtract days from a date. This is equivalent to the `Dates.Day` struct.
```julia
julia> rd"3d" + Date(2019,1,1)
2019-01-04
julia> RDates.Day(3) + Date(2019,1,1)
2019-01-04
julia> rd"-2d" + Date(2019,1,1)
2018-12-30
```

## Weeks
Provides us with the ability to add or subtract weeks from a date. This is equivalent to the `Dates.Week` struct.
```julia
julia> rd"3w" + Date(2019,1,1)
2019-01-22
julia> RDates.Week(3) + Date(2019,1,1)
2019-01-22
julia> rd"-2w" + Date(2019,1,1)
2018-12-18
```

## Months
Adding months to a date is a surprisingly complex operation. For example
- What should happen if I add one month to the 31st January?
- Should adding one month to the 30th April maintain the end of month?

To allow us to have this level of flexibility, we need to introduce two new conventions

#### Invalid Day Convention
We define conventions to determine what to do if adding (or subtracting) the months leads us to an invalid day.
- **Last Day Of Month** or **LDOM** means that you should fall back to the last day of the current month.
- **First Day Of Next Month** or **FDONM** means that you should move forward to the first day of the next month.
- **Nth Day Of Next Month** or **NDONM** means that you should move forward into the next month the number of days past you have ended up past the last day of month. This is will only differ to *FDONM* if you fall in February.

#### Month Increment Convention
We also need to understand what to do when you add a month. Most of the time you'll be just looking to maintain the same day, but it can also sometimes be preferable to maintain the last day of the month.

- **Preserve Day Of Month** or **PDOM** means that we'll always make sure we land on the same day (though invalid day conventions may kick in).
- **Preserve Day Of Month And End Of Month** or **PDOMEOM** means that we'll preserve the day of the month, unless the base date falls on the end of the month, then we'll keep to the end of the month going forward (noting that this will be applied prior to invalid day conventions). This can also be provided a set of calendars, to allow it to work as the last business day of the month.


We can now combine these together to start working with month adjustments. These arguments are passed in square brackets, semi colon separated, after the `m` using their shortened naming conventions.

```julia
julia> rd"1m[LDOM;PDOM]" + Date(2019,1,31)
2019-02-28
julia> rd"1m[FDONM;PDOM]" + Date(2019,1,31)
2019-03-01
julia> rd"1m[NDONM;PDOM]" + Date(2019,1,31)
2019-03-03
julia> rd"1m[NDONM;PDOMEOM]" + Date(2019,1,31)
2019-02-28
```

We also provide default values for the conventions, with *Last Day Of Month* for invalid days and *Preserve Day Of Month* for our monthly increment.

```julia
julia> rd"1m" == rd"1m[LDOM;PDOM]"
true
```

## Years
Adding years is generally simple, except when we have to deal with February and leap years. As such, we use the same conventions as for months.

```julia
julia> rd"1y[LDOM;PDOM]" + Date(2019,2,28)
2020-02-28
julia> rd"1y[LDOM;PDOMEOM]" + Date(2019,2,28)
2020-02-29
julia> rd"1y[LDOM;PDOM]" + Date(2020,2,29)
2021-02-28
julia> rd"1y[FDOM;PDOM]" + Date(2020,2,29)
2021-03-01
```

Similar to months we also provide default values for the conventions, with *Last Day Of Month* for invalid days and *Preserve Day Of Month* for our monthly increment.

```julia
julia> rd"1y" == rd"1y[LDOM;PDOM]"
true
```

## First And Last Day's Of The Month
Some similar operators that let you get the first or the last day of month from the given date.
```julia
julia> rd"FDOM" + Date(2019,1,13)
2019-01-01
julia> rd"LDOM" + Date(2019,1,13)
2019-01-31
```

## Easter
A date that is well known from hunting eggs and pictures of bunnies, it's a rather tricky calculation to perform. We provide a simple method to allow you to get the Easter for the given year (or appropriately incremented or decremented from the given year)

To get Easter for the given year we can use `0E`, for next year's Easter it's `1E` and for the Easter two years ago it would be `-2E`

!!! note

    `0E` will get the Easter of the current year, so it could be before or after the date you've provided.

```julia
julia> rd"0E" + Date(2019,1,1)
2019-04-21
julia> rd"0E" + Date(2019,8,1)
2019-04-21
julia> rd"10E" + Date(2019,8,1)
2029-04-01
```

## Day Month
We can have the ability to apply a specific day and month pair to the given year. This is provided using the standard 3 letter acronym for months
!!! note

    `1MAR` will get the 1st of March of the current year, so it could be before or after the date you've provided.

```julia
julia> rd"1MAR" + Date(2019,1,1)
2019-03-01
julia> rd"29OCT" + Date(2020,12,1)
2020-10-29
```

## Day Month Year
We can have the ability to move to a specific date, irrespective of the given date. This is provided using the standard 3 letter acronym for months and the full year.
```julia
julia> rd"1MAR2020" + Date(2019,1,1)
2020-03-01
julia> rd"29OCT1993" + Date(2020,12,1)
1993-10-29
```

## Weekdays
It's quite common to want to ask for what is the next Saturday or the last Tuesday. This provides a mechanism for querying based on that.

For the grammar, the weekdays are given by their 3 letter acronym.

The count associated tells us what we're looking for. `1MON` will ask for the next Monday, exclusive of today. You can make it inclusive by adding `!` to `1MON!`. All other counts will then be additional weeks (forward or back) from this point.

```julia
julia> rd"1WED" + Date(2019,9,24) # A Tuesday
2019-09-25
julia> rd"1WED" + Date(2019,9,25)
2019-10-02
julia> rd"1WED!" + Date(2019,9,25)
2019-09-25
julia> rd"0WED" + Date(2019,9,26)
2019-10-02
```

## Nth Weekday
There are cases when you need to get a weekday in a given month, such as the 3rd Wednesday for [IMM Dates](https://en.wikipedia.org/wiki/IMM_dates). This can be achieved with the Nth Weekday (using the 3 letter acronym for the weekdays)

```julia
julia> rd"1st MON" + Date(2019,9,24)
2019-09-02
julia> rd"3rd WED" + Date(2019,12,1)
2019-12-18
```

## Nth Last Weekday
Similarly you can work backwards if required
```julia
julia> rd"Last MON" + Date(2019,9,24)
2019-09-30
julia> rd"3rd Last WED" + Date(2019,12,1)
2019-12-11
```
