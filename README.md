# RDates

*A relative date library for Julia*

| **Documentation**                                                         | **Build Status**                                              |
|:-------------------------------------------------------------------------:|:-------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][travis-img]][travis-url] [![][codecov-img]][codecov-url] |

This is a project that builds around the [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/) module to allow complex date operations.  

The aim is to provide a standard toolset to allow you to answer questions such as *when is the next Easter* or *what is the 3rd Wednesday of March next year?*

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


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://infinitechai.github.io/RDates.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://infinitechai.github.io/RDates.jl/stable

[travis-img]: https://travis-ci.org/InfiniteChai/RDates.jl.svg?branch=master
[travis-url]: https://travis-ci.org/InfiniteChai/RDates.jl

[codecov-img]: https://codecov.io/gh/InfiniteChai/RDates.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/InfiniteChai/RDates.jl

[issues-url]: https://github.com/JuliaDocs/Documenter.jl/issues
