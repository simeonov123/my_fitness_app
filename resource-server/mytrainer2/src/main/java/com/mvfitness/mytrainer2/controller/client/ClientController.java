// src/main/java/com/mvfitness/mytrainer2/controller/client/ClientController.java
package com.mvfitness.mytrainer2.controller.client;

import com.mvfitness.mytrainer2.dto.ClientDto;
import com.mvfitness.mytrainer2.service.client.ClientService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping("/trainer/clients")
@RequiredArgsConstructor
public class ClientController {

    private final ClientService svc;

    // Helper to pull Keycloak user id (sub) from the JWT
    private static String kcUserId(JwtAuthenticationToken auth) {
        return auth.getToken().getSubject();
    }

    @GetMapping
    public Page<ClientDto> list(
            JwtAuthenticationToken auth,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "newest") String sort
    ) {
        return svc.list(kcUserId(auth), q, page, size, sort);
    }

    @GetMapping("/{id}")
    public ClientDto get(JwtAuthenticationToken auth,
                         @PathVariable Long id) {
        return svc.get(kcUserId(auth), id);
    }

    @PostMapping
    public ClientDto create(JwtAuthenticationToken auth,
                            @RequestBody ClientDto dto) {
        return svc.create(kcUserId(auth), dto);
    }

    @PutMapping("/{id}")
    public ClientDto update(JwtAuthenticationToken auth,
                            @PathVariable Long id,
                            @RequestBody ClientDto dto) {
        return svc.update(kcUserId(auth), id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken auth,
                                       @PathVariable Long id) {
        svc.delete(kcUserId(auth), id);
        return ResponseEntity.noContent().build();
    }
}
