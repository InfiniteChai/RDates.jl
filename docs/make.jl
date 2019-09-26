push!(LOAD_PATH,"../src/")
using Documenter, RDates

makedocs(
    modules = [RDates],
    clean = false,
    format = :html,
    sitename = "RDates.jl",
    authors = "Iain Skett",
    pages = [
        "Introduction" => "index.md",
        "Primitives" => "primitives.md",
        "Combinations" => "combinations.md",
        "Business Days" => "business_days.md",
    ],
)

deploydocs(
    julia = "1.1",
    repo = "github.com/InfiniteChai/RDates.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
