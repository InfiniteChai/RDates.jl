import Dates

Base.show(io::IO, rdate::Day) = print(io, "$(rdate.days)d")
Base.show(io::IO, rdate::Week) = print(io, "$(rdate.weeks)w")
Base.show(io::IO, rdate::Month) = print(io, "$(rdate.months)m")
Base.show(io::IO, rdate::Year) = print(io, "$(rdate.years)y")
Base.show(io::IO, rdate::Easter) = print(io, "$(rdate.yearδ)E")
Base.show(io::IO, ::FDOM) = print(io, "FDOM")
Base.show(io::IO, ::LDOM) = print(io, "LDOM")
Base.show(io::IO, rdate::DayMonth) = print(io, "$(rdate.day)$(uppercase(Dates.ENGLISH.months_abbr[rdate.month]))")
Base.show(io::IO, rdate::NthWeekdays) = print(io, "$(NTH_PERIODS[rdate.period]) $(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")
Base.show(io::IO, rdate::NthLastWeekdays) = print(io, "$(NTH_LAST_PERIODS[rdate.period]) $(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")
function Base.show(io::IO, rdate::RDateRepeat)
    print(io, "$(rdate.count)*(")
    Base.show(io, rdate.part)
    print(io, ")")
end
function Base.show(io::IO, rdate::RDateCompound)
    for (i,part) in enumerate(rdate.parts)
        if i > 1
            print(io, "+")
        end
        Base.show(io, part)
    end
end
