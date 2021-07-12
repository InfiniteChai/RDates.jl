push!(LOAD_PATH,"../src/")
using Documenter, RDates

makedocs(
    modules = [RDates],
    clean = false,
    format = Documenter.HTML(),
    sitename = "RDates.jl",
    authors = "Iain Skett",
    pages = [
        "Introduction" => "index.md",
        "Primitives" => "primitives.md",
        "Months and Years" => "months_and_years.md",
        "Combinations" => "combinations.md",
        "Business Days" => "business_days.md",
        "Ranges" => "ranges.md"
    ],
)

deploydocs(
    repo = "github.com/InfiniteChai/RDates.jl.git"
)
