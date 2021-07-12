# Introduction

*A relative date library for Julia*

This is a project that builds around the [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/) module to allow complex date arithmetic.  

The aim is to provide a standard toolset to allow you to answer questions such as *when is the next Easter* or *what are the next 4 [IMM](https://en.wikipedia.org/wiki/IMM_dates) dates from today?*

## Package Features ##
- A generic, extendable algebra for date operations with a rich set of primitives.
- A composable design to allow complex combinations of relative date operations.
- An extendable parsing library to provide a language to describe relative dates.
- An interface for integrating holiday calendar systems.

## Installation

RDates can be installed using the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run
```julia-repl
pkg> add RDates
```

At this point you can now start using RDates in your current Julia session using the following command
```julia-repl
julia> using RDates
```

## Answering Those Questions

So while the documentation will provide the details, let's see a quick start on how it works

- When is the next Easter?

```julia-repl
julia> rd"Next(0E,1E)" + Date(2021,7,12)
2022-04-17
```

- What are the next 4 [IMM](https://en.wikipedia.org/wiki/IMM_dates) dates?

```julia-repl
julia> d = Date(2021,7,12)
julia> collect(Iterators.take(range(d, rd"1MAR+3m+3rd WED"), 4))
4-element Vector{Date}:
 2021-09-15
 2021-12-15
 2022-03-16
 2022-06-15
```
