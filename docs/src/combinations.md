# Combinations

One of the key features of RDates is to allow us to combine primitive operations to provide a generalised method to describe date adjustments.

We now provide details on the different forms of combinators that can be used within the package.

## Negation

Where applicable, the primitive operations support negation. This can be achieved by applying the `-` operator on the RDate.

```julia
julia> Date(2019,1,1) - rd"1d"
2018-12-31
julia> -rd"3w" + Date(2019,1,1)
2018-12-11
```

!!! warning

    Not all RDates support negation. For example `1st WED` does not have a reasonable inversion.
    ```julia
    julia> -rd"1st WED"
    ERROR: RDates.NthWeekdays does not support negation
    ```

## Addition

All RDates can be combined together via addition. The components are applied from left to right.

```julia
julia> rd"1d + 1y" + Date(2019,1,1)
2020-01-02
julia> rd"1MAR + 3rd WED" + Date(2019,1,1)
2019-03-20
```

!!! note

    Where possible, addition operations may be optimised to reduce down to simpler state.
    ```julia
    julia> rd"1d + 1d" == rd"2d"
    true
    ```

!!! warning

    The alegbra of month addition is not always straight forward. Make sure you're clear on exactly what you want to achieve.
    ```julia
    julia> rd"2m" + Date(2019,1,31)
    2019-03-31
    julia> rd"1m + 1m" + Date(2019,1,31)
    2019-03-28
    ```

## Repeats

You can multiply any RDate by a positive integer to repeat its application, or *rolling* it, that many times.

```julia
julia> rd"2*roll(1m)" + Date(2019,1,31)
2019-03-28
julia> rd"-5*roll(3d + 4w)" + Date(2019,1,1)
2018-07-30
```

It's worth noting that we also support non rolled multiplication, which will attempt to embed the multiplication within the rdate.
```julia
julia> rd"2*1m" + Date(2019,1,31)
2019-03-31
julia> rd"2*1m" == rd"2m"
true
```
