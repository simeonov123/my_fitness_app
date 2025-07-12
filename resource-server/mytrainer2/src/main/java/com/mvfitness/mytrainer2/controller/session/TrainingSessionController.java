package com.mvfitness.mytrainer2.controller.session;

import com.mvfitness.mytrainer2.dto.CalendarDayCountDto;
import com.mvfitness.mytrainer2.dto.TrainingSessionDto;
import com.mvfitness.mytrainer2.service.session.TrainingSessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@PreAuthorize("hasRole('TRAINER')")
@RestController @RequiredArgsConstructor
@RequestMapping("/trainer/training-sessions")
public class TrainingSessionController {

    private final TrainingSessionService svc;
    private static String kc(JwtAuthenticationToken a) { return a.getToken().getSubject(); }

    @GetMapping
    public Page<TrainingSessionDto> list(
            JwtAuthenticationToken auth,
            @RequestParam(required=false) String q,
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="10") int size,
            @RequestParam(defaultValue="newest") String sort) {
        return svc.list(kc(auth), q, page, size, sort);
    }


    @GetMapping("/calendar")
    public List<CalendarDayCountDto> countsBetween(
            JwtAuthenticationToken auth,
            @RequestParam LocalDate from,
            @RequestParam LocalDate to) {
        return svc.calendarCounts(kc(auth), from, to);
    }

    @GetMapping("/day/{day}")
    public Page<TrainingSessionDto> listDay(
            JwtAuthenticationToken auth,
            @PathVariable LocalDate day,
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="10") int size) {
        return svc.listForDay(kc(auth), day, page, size);
    }
    @GetMapping("/{id}")
    public TrainingSessionDto get(JwtAuthenticationToken auth, @PathVariable Long id) {
        return svc.get(kc(auth), id);
    }

    @PostMapping
    public TrainingSessionDto create(JwtAuthenticationToken auth,
                                     @RequestBody TrainingSessionDto dto) {
        return svc.create(kc(auth), dto);
    }

    @PutMapping("/{id}")
    public TrainingSessionDto update(JwtAuthenticationToken auth,
                                     @PathVariable Long id,
                                     @RequestBody TrainingSessionDto dto) {
        return svc.update(kc(auth), id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken auth, @PathVariable Long id) {
        svc.delete(kc(auth), id);
        return ResponseEntity.noContent().build();
    }
}
