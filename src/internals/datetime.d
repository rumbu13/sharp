module internals.datetime;

import system;
import internals.checked;

enum long hoursPerDay = 24;
enum long minutesPerHour = 60;
enum long secondsPerMinute = 60;
enum long millisecondsPerSecond = 1000;
enum long ticksPerMillisecond = 1000;

enum long minutesPerDay = minutesPerHour * hoursPerDay;
enum long secondsPerHour = secondsPerMinute * minutesPerHour;
enum long millisecondsPerMinute = millisecondsPerSecond * secondsPerMinute;
enum long ticksPerSecond = ticksPerMillisecond * millisecondsPerSecond;

enum long secondsPerDay = secondsPerHour * hoursPerDay;
enum long millisecondsPerHour = millisecondsPerMinute * minutesPerHour;
enum long ticksPerMinute = ticksPerSecond * secondsPerMinute;

enum long millisecondsPerDay = millisecondsPerHour * hoursPerDay;
enum long ticksPerHour = ticksPerMinute * millisecondsPerHour;

enum long ticksPerDay = ticksPerHour * millisecondsPerDay;

enum long daysPerYear = 365;
enum long daysPer4Years = daysPerYear * 4 + 1;
enum long daysPer100Years = daysPer4Years * 25 - 1;
enum long daysPer400Years = daysPer100Years * 4 + 1;

enum long days1601 = daysPer400Years * 4;
enum long days1899 = days1601 + daysPer100Years * 3 - 367;
enum long days10000 = daysPer400Years * 25 - 366;

enum long minTicks = 0;
enum long maxTicks = (daysPer400Years * 25 - 366) * ticksPerDay - 1;
enum long maxMilliseconds = days10000 * millisecondsPerDay;
enum long minMilliseconds = - maxMilliseconds;

enum long fileTimeOffset = days1601 * ticksPerDay;
enum long doubleTimeOffset = days1899 * ticksPerDay;

immutable daysPerMonth =         [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
immutable daysPerMonthLeap =     [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

immutable daysToPerMonth =       [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];
immutable daysToPerMonthLeap =   [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366];

long getTicks(in double value, in int scale)
{
    long m = cast(long)(value * scale + (value >= 0 ? 0.5 : -0.5));
    checkRange(m, minMilliseconds, maxMilliseconds, "milliseconds");
    return m * ticksPerMillisecond;
}

long getDays(in int year, in int month, in int day)
{
    checkRange(year, 1, 9999, "year");
    checkRange(month, 1, 12, "month");
    bool leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);   
    checkRange(day, 1, leap ? daysPerMonthLeap[month - 1] : daysPerMonth[month - 1], "day");
    int y = year - 1;
    return y * 365 + y / 4 - y / 100 + y / 400 + (leap ? daysToPerMonthLeap[month - 1] : daysToPerMonth[month - 1]) + day - 1;
}

struct DateFormatter
{
    static immutable wchar[] dateTimeFormats = 
    [ 'd', 'D', 'f', 'F', 'g', 'G', 'm', 'M', 'o', 'O', 'r', 'R', 's', 't', 'T', 'u', 'U', 'y', 'Y'];
    static immutable wstring roundtripFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.fffffffK";
}