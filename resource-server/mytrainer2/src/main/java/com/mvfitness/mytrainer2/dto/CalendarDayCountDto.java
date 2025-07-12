package com.mvfitness.mytrainer2.dto;

import java.time.LocalDate;

/**
 * Lightweight DTO used by the calendar widget:
 * only the date (at midnight) and amount of sessions scheduled for that day.
 */
public record CalendarDayCountDto(
        LocalDate date,
        long     count
) { }
