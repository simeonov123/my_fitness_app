// ─── src/main/java/com/mvfitness/mytrainer2/controller/nutrition/NutritionPlanTemplateController.java
package com.mvfitness.mytrainer2.controller.nutrition;

import com.mvfitness.mytrainer2.dto.NutritionPlanTemplateDto;
import com.mvfitness.mytrainer2.service.nutrition.NutritionPlanTemplateService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping("/trainer/nutrition-templates")
@RequiredArgsConstructor
public class NutritionPlanTemplateController {

    private final NutritionPlanTemplateService svc;

    /** Pull Keycloak user id (`sub`) from JWT */
    private static String kcUserId(JwtAuthenticationToken auth) {
        return auth.getToken().getSubject();
    }

    @GetMapping
    public Page<NutritionPlanTemplateDto> list(
            JwtAuthenticationToken auth,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "newest") String sort
    ) {
        return svc.list(kcUserId(auth), q, page, size, sort);
    }

    @GetMapping("/{id}")
    public NutritionPlanTemplateDto get(
            JwtAuthenticationToken auth,
            @PathVariable Long id
    ) {
        return svc.get(kcUserId(auth), id);
    }

    @PostMapping
    public NutritionPlanTemplateDto create(
            JwtAuthenticationToken auth,
            @RequestBody NutritionPlanTemplateDto dto
    ) {
        return svc.create(kcUserId(auth), dto);
    }

    @PutMapping("/{id}")
    public NutritionPlanTemplateDto update(
            JwtAuthenticationToken auth,
            @PathVariable Long id,
            @RequestBody NutritionPlanTemplateDto dto
    ) {
        return svc.update(kcUserId(auth), id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            JwtAuthenticationToken auth,
            @PathVariable Long id
    ) {
        svc.delete(kcUserId(auth), id);
        return ResponseEntity.noContent().build();
    }
}
