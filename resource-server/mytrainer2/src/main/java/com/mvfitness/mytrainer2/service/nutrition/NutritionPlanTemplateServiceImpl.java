// ─── src/main/java/com/mvfitness/mytrainer2/service/nutrition/NutritionPlanTemplateServiceImpl.java
package com.mvfitness.mytrainer2.service.nutrition;

import com.mvfitness.mytrainer2.domain.NutritionPlanTemplate;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.dto.NutritionPlanTemplateDto;
import com.mvfitness.mytrainer2.mapper.NutritionPlanTemplateMapper;
import com.mvfitness.mytrainer2.repository.NutritionPlanTemplateRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class NutritionPlanTemplateServiceImpl implements NutritionPlanTemplateService {

    private final NutritionPlanTemplateRepository repo;
    private final UserRepository users;

    // ─── helpers ───────────────────────────────────────────────────
    private User trainerOr404(String kcUserId) {
        User u = users.findByKeycloakUserId(kcUserId);
        if (u == null)
            throw new IllegalArgumentException("Trainer not found for KC id: " + kcUserId);
        return u;
    }

    private NutritionPlanTemplate ownedOr404(String kcUserId, Long id) {
        User trainer = trainerOr404(kcUserId);
        NutritionPlanTemplate t = repo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Template not found or not yours"));
        if (!t.getTrainer().getId().equals(trainer.getId()))
            throw new IllegalArgumentException("Template not found or not yours");
        return t;
    }
    // ───────────────────────────────────────────────────────────────

    @Override @Transactional(readOnly = true)
    public Page<NutritionPlanTemplateDto> list(String kcUserId, String q, int page, int size, String sort) {
        Sort order = switch (sort) {
            case "name"      -> Sort.by("name").ascending();
            case "name_desc" -> Sort.by("name").descending();
            case "oldest"    -> Sort.by("createdAt").ascending();
            default          -> Sort.by("createdAt").descending();   // newest
        };

        User trainer = trainerOr404(kcUserId);
        Page<NutritionPlanTemplate> p = repo.findByTrainerAndNameContainingIgnoreCase(
                trainer,
                q == null ? "" : q,
                PageRequest.of(page, size, order)
        );
        return p.map(NutritionPlanTemplateMapper::toDto);
    }

    @Override @Transactional(readOnly = true)
    public NutritionPlanTemplateDto get(String kcUserId, Long id) {
        return NutritionPlanTemplateMapper.toDto(ownedOr404(kcUserId, id));
    }

    @Override
    public NutritionPlanTemplateDto create(String kcUserId, NutritionPlanTemplateDto dto) {
        NutritionPlanTemplate t = NutritionPlanTemplate.builder()
                .trainer(trainerOr404(kcUserId))
                .name(dto.name())
                .description(dto.description())
                .build();
        NutritionPlanTemplateMapper.updateEntity(t, dto); // populate items, too
        return NutritionPlanTemplateMapper.toDto(repo.save(t));
    }

    @Override
    public NutritionPlanTemplateDto update(String kcUserId, Long id, NutritionPlanTemplateDto dto) {
        NutritionPlanTemplate t = ownedOr404(kcUserId, id);
        NutritionPlanTemplateMapper.updateEntity(t, dto);
        return NutritionPlanTemplateMapper.toDto(repo.save(t));
    }

    @Override
    public void delete(String kcUserId, Long id) {
        repo.delete(ownedOr404(kcUserId, id));
    }
}
