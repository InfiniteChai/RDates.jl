import Dates

"""
    HolidayRoundingNBD <: HolidayRoundingConvention

Move to the next business day when a date falls on a holiday. Uses "NBD" for
short hand. In finance, this is commonly called "Following"
"""
struct HolidayRoundingNBD <: HolidayRoundingConvention end
function apply(::HolidayRoundingNBD, date::Dates.Date, calendar::Calendar)::Dates.Date
    while is_holiday(calendar, date)
        date += Dates.Day(1)
    end
    date
end
Base.show(io::IO, ::HolidayRoundingNBD) = print(io, "NBD")


"""
    HolidayRoundingPBD <: HolidayRoundingConvention

Move to the previous business day when a date falls on a holiday. Uses "PBD" for
short hand. In finance, this is commonly called "Previous"
"""
struct HolidayRoundingPBD <: HolidayRoundingConvention end
function apply(::HolidayRoundingPBD, date::Dates.Date, calendar::Calendar)::Dates.Date
    while is_holiday(calendar, date)
        date -= Dates.Day(1)
    end
    date
end
Base.show(io::IO, ::HolidayRoundingPBD) = print(io, "PBD")

"""
    HolidayRoundingNBDSM <: HolidayRoundingConvention

Move to the next business day when a date falls on a holiday, unless the adjusted
date would be in the next month, then go the previous business date instead.
Uses "NBDSM" for short hand. In finance, this is commonly called "Modified Following"
"""
struct HolidayRoundingNBDSM <: HolidayRoundingConvention end
function apply(::HolidayRoundingNBDSM, date::Dates.Date, calendar::Calendar)::Dates.Date
    new_date = date
    while is_holiday(calendar, new_date)
        new_date += Dates.Day(1)
    end

    if Dates.month(new_date) != Dates.month(date)
        new_date = date
        while is_holiday(calendar, new_date)
            new_date -= Dates.Day(1)
        end
    end

    new_date
end
Base.show(io::IO, ::HolidayRoundingNBDSM) = print(io, "NBDSM")


"""
    HolidayRoundingPBDSM <: HolidayRoundingConvention

Move to the previous business day when a date falls on a holiday, unless the adjusted
date would be in the previous month, then go the next business date instead.
Uses "PBDSM" for short hand. In finance, this is commonly called "Modified Previous"
"""
struct HolidayRoundingPBDSM <: HolidayRoundingConvention end
function apply(::HolidayRoundingPBDSM, date::Dates.Date, calendar::Calendar)::Dates.Date
    new_date = date
    while is_holiday(calendar, new_date)
        new_date -= Dates.Day(1)
    end

    if Dates.month(new_date) != Dates.month(date)
        new_date = date
        while is_holiday(calendar, new_date)
            new_date += Dates.Day(1)
        end
    end

    new_date
end
Base.show(io::IO, ::HolidayRoundingPBDSM) = print(io, "PBDSM")


"""
    HolidayRoundingNR <: HolidayRoundingConvention

No rounding, so just give back the same date even though it's a holiday. Uses
"NR" for short hand. In finance, this is commonly called "Unadjusted" or "Actual"
"""
struct HolidayRoundingNR <: HolidayRoundingConvention end
apply(::HolidayRoundingNR, date::Dates.Date, ::Calendar) = date
Base.show(io::IO, ::HolidayRoundingNR) = print(io, "NR")


"""
    HolidayRoundingNearest <: HolidayRoundingConvention

Move to the nearest business day, with the next one taking precedence in a tie.
This is commonly used for US calendars which will adjust Sat to Fri and Sun to Mon
for their fixed date holidays. Uses "NEAR" for short hand.
"""
struct HolidayRoundingNearest <: HolidayRoundingConvention end
function apply(::HolidayRoundingNearest, date::Dates.Date, cal::Calendar)
    is_holiday(cal, date) || return date
    count = 0
    result = nothing
    while result === nothing
        up_date = date + Dates.Day(count)
        if !is_holiday(cal, up_date)
            result = up_date
        else
            down_date = date - Dates.Day(count)
            if !is_holiday(cal, down_date)
                result = down_date
            end
        end
        count += 1
    end
    result
end
Base.show(io::IO, ::HolidayRoundingNearest) = print(io, "NEAR")


const HOLIDAY_ROUNDING_MAPPINGS = Dict(
    "NR" => HolidayRoundingNR(),
    "NBD" => HolidayRoundingNBD(),
    "PBD" => HolidayRoundingPBD(),
    "NBDSM" => HolidayRoundingNBDSM(),
    "PBDSM" => HolidayRoundingPBDSM(),
    "NEAR" => HolidayRoundingNearest()
)
