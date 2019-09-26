# Ranges

As well as performing relative date operations, you can also get a range of dates for a given period. This can provide an infinite range, or appropriate clipped.

```julia
julia> collect(Iterators.take(range(Date(2019,4,17), rd"1d"),3))
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

This should give the basic building blocks to also come up with as complex functionality as required. For example, to get the next 3 future [IMM Dates](https://en.wikipedia.org/wiki/IMM_dates) we can go as follows

```julia
julia> today = Date(2017,10,27)
julia> start = rd"1MAR+3rd WED" + today
julia> immdates = Iterators.take(Iterators.filter(x -> x >= today, range(start, rd"3m+3rd WED")), 3)
julia> collect(immdates)
3-element Array{Date,1}:
 2017-12-20
 2018-03-21
 2018-06-20
```
