# Combinations

One of the key features of RDates is to allow us to combine primitive operations to provide a generalised method to describe date adjustments.

## Negation

All our primitive operations provide a negative operation, which is achieved by applying the `-` operator
to the `RDate`.

```julia-repl
julia> Date(2019,1,1) - RDates.Day(1)
2018-12-31
julia> -RDates.Week(3) + Date(2019,1,1)
2018-12-11
```

!!! note

    While all our RDates support negation, they may not have an effect and will just return itself.

    ```julia-repl
    julia> -rd"1st WED" == rd"1st WED"
    true
    ```

## Addition

All RDates can be combined together via addition. The components are applied from left to right.

```julia-repl
julia> rd"1d + 1y" + Date(2019,1,1)
2020-01-02
julia> rd"1MAR + 3rd WED" + Date(2019,1,1)
2019-03-20
```

!!! note
    Where possible, addition operations may be optimised to reduce down to simpler state. This will
    always be done in a way in which we maintain the expected behaviour.
    ```julia-repl
    julia> rd"1d + 1d" == rd"2d"
    true
    ```

!!! warning

    The alegbra of month addition is not always straight forward. Make sure you're clear on exactly what you want to achieve.
    ```julia-repl
    julia> rd"2m" + Date(2019,1,31)
    2019-03-31
    julia> rd"1m + 1m" + Date(2019,1,31)
    2019-03-28
    ```

## Multiplication and Repeats

Every RDate supports multiplication and this will usually multiply it's underlying count. For most primitives
this is completely understandable due to the inherent link between addition and multiplication.

```julia-repl
julia> RDates.Day(2) * 5
10d
julia> RDates.Week(2) * -5
-10w
```

For RDates which do not have a natural count then the multiplication will just return itself

```julia-repl
julia> 10 * RDates.NthWeekdays(:MON, 1)
1st MON
```

However when we come to handling months (and by extension years, though in rarer cases) we need to
be more careful. We set a convention that multiplication is equivalent to multiplication of the internal
count and so we won't get the same result as adding it n times.

```julia-repl
julia> 2 * RDates.Month(1)
2m[LDOM;PDOM]
julia> rd"2 * 1m"
2m[LDOM;PDOM]
julia> 2 * RDates.Month(1) + Date(2019,1,31)
2019-03-31
julia> RDates.Month(1) + RDates.Month(1) + Date(2019,1,31)
2019-03-28
```

It may be though that you want that handling and so we introduce the `Repeat` operator to support that.
This operator will repeat the application of the internalised rdate, rather than passing the multiplier
through.

```julia-repl
julia> 2 * RDates.Repeat(RDates.Month(1))
2*Repeat(1m[PDOM;LDOM])
julia> 2 * RDates.Repeat(RDates.Month(1)) + Date(2019,1,31)
2019-03-28
julia> rd"2*Repeat(1m)" + Date(2019,1,31)
2019-03-28
```

## Other Operators

```@docs
RDates.Next

RDates.Previous
```
