# Months and Years

Adding months to a date is a surprisingly complex operation and so we've created a
dedicated page to go through the details. For example
- What should happen if I add one month to the 31st January?
- Should adding one month to the 30th April maintain the end of month?

Years are less complex, but still suffer from the same edge case due to leap years
and the 29th February. As such, we incorporate the same conventions.

To give us the level of flexibility, we need to introduce two conventions to support
us.

## Month Increment Convention
When we add a month to a date, we need to determine what we should do with the day. Most of the
time we'll maintain the same day, but sometimes we may want to maintain the last day of the month,
which is a common feature in financial contracts.

```@docs
RDates.MonthIncrementPDOM

RDates.MonthIncrementPDOMEOM
```

## Invalid Day Convention
The next convention we need is what to do if our increment leaves us on an invalid day of the month.

```@docs
RDates.InvalidDayLDOM

RDates.InvalidDayFDONM

RDates.InvalidDayNDONM
```

We now have all the conventions we need to handle month and year adjustments

```@docs
RDates.Month

RDates.Year
```
