module RDates

include("abstracts.jl")
# Rounding and Compounds defined upfront as we need them for the grammar
include("rounding.jl")
include("compounds.jl")

include("grammar.jl")
include("monthinc.jl")
include("invalidday.jl")

# The various basic implementations (along with shows and grammar registrations)
include("primitives.jl")

include("ranges.jl")
include("calendars.jl")
# include("io.jl")
# Export the macro and non-macro parsers.
export @rd_str
export rdate
export is_holiday, holidays, holidaycount, bizdaycount
export calendar
export apply
export SimpleCalendarManager, setcalendar!, setcachedcalendar!
export WeekendCalendar, CachedCalendar

end # module RDates
