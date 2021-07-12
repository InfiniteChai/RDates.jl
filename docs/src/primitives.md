# Primitives

RDates is designed to allow complex date operations to be completed using basic primitive types. Each of these primitive types and operations are explained in more detail in subsequent sections.

We now go through each of the primitive types, from which we can combine together using compounding operations. Also take note of the examples and the associated short-hand that we can use to define them
with the `rd""` macro.

```@docs
RDates.Day

RDates.Week

RDates.FDOM

RDates.LDOM

RDates.Easter

RDates.DayMonth

RDates.Date

RDates.NthWeekdays

RDates.NthLastWeekdays

RDates.Weekdays
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
