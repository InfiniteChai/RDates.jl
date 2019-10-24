# Introduction

*A relative date library for Julia*

This is a project that builds around the [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/) module to allow complex date operations.  

The aim is to provide a standard toolset to allow you to answer questions such as *when is the next Easter* or *what are the next 4 IMM dates from today?*

## Package Features ##
- A generic, extendable algebra for date operations with a rich set of primitives.
- A composable design to allow complex combinations of relative date operations.
- An extendable parsing library to provide a language to describe relative dates.
- An interface for integrating holiday calendar systems.

## Installation

RDates can be installed using the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run
```julia
pkg> add RDates
```

At this point you can now start using RDates in your current Julia session using the following command
```julia
julia> using RDates
```
