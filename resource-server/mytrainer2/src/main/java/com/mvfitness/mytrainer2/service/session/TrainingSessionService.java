package com.mvfitness.mytrainer2.service.session;

import com.mvfitness.mytrainer2.dto.CalendarDayCountDto;
import com.mvfitness.mytrainer2.dto.TrainingSessionDto;
import org.springframework.data.domain.Page;

import java.time.LocalDate;
import java.util.List;

public interface TrainingSessionService {
    Page<TrainingSessionDto> list(String kcUserId, String q, int page, int size, String sort);
    TrainingSessionDto       get (String kcUserId, Long id);
    TrainingSessionDto       create(String kcUserId, TrainingSessionDto dto);
    TrainingSessionDto       update(String kcUserId, Long id, TrainingSessionDto dto);
    void                     delete(String kcUserId, Long id);
    List<CalendarDayCountDto> calendarCounts(String kcUserId,
                                             LocalDate from,
                                             LocalDate to);

    Page<TrainingSessionDto>  listForDay     (String kcUserId,
                                              LocalDate day,
                                              int page,
                                              int size);
}
