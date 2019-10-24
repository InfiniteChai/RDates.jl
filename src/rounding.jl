import Dates

struct HolidayRoundingNBD <: HolidayRoundingConvention end
function apply(::HolidayRoundingNBD, date::Dates.Date, calendar::Calendar)::Dates.Date
    while is_holiday(calendar, date)
        date += Dates.Day(1)
    end
    date
end

struct HolidayRoundingPBD <: HolidayRoundingConvention end
function apply(::HolidayRoundingPBD, date::Dates.Date, calendar::Calendar)::Dates.Date
    while is_holiday(calendar, date)
        date -= Dates.Day(1)
    end
    date
end

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

struct HolidayRoundingNR <: HolidayRoundingConvention end
apply(::HolidayRoundingNR, date::Dates.Date, ::Calendar) = date

const HOLIDAY_ROUNDING_MAPPINGS = Dict("NR" => HolidayRoundingNR(), "NBD" => HolidayRoundingNBD(), "PBD" => HolidayRoundingPBD(), "NBDSM" => HolidayRoundingNBDSM(), "PBDSM" => HolidayRoundingPBDSM())
