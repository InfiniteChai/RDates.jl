# Ranges

As well as performing relative date operations, you can also get a range of dates for a given period. This can provide an infinite range, or appropriate clipped.

```julia
julia> collect(Iterators.take(range(Date(2017,1,25), rd"1d"),3))
3-element Array{Date,1}:
 2017-01-25
 2017-01-26
 2017-01-27
julia> collect(range(Date(2019,4,17), Date(2019,4,21), rd"2d"))
3-element Array{Date,1}:
 2019-04-17
 2019-04-19
 2019-04-21
julia> collect(range(Date(2019,4,17), Date(2019,4,21), rd"1d", inc_from=false, inc_to=false))
3-element Array{Date,1}:
 2019-04-18
 2019-04-19
 2019-04-20
```

It should be noted that the range under the hood applies *multiply_no_roll* for incremental counts to the  period, so by using *RDates.Date* we can provide a reference point that is isolated from the start date of the range.

This gives us the basic building blocks to also come up with complex functionality. For example, to get the next 4 future [IMM Dates](https://en.wikipedia.org/wiki/IMM_dates) we can do the following

```julia
julia> today = Date(2017,10,27)
julia> immdates = Iterators.take(Iterators.filter(x -> x >= today, range(today, RDates.Date(today) + rd"1MAR+3m+3rd WED")), 4)
julia> collect(immdates)
4-element Array{Date,1}:
 2017-12-20
 2018-03-21
 2018-06-20
 2018-09-19
```
!!! note

    While this works as expected, it will always be more efficient to reduce the rdate calculations being applied within the iterator. As such, calculating the 1st of March as a date first would save some unnecessary computations.
