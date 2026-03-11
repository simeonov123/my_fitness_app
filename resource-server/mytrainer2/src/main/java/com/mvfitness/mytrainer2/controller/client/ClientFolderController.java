package com.mvfitness.mytrainer2.controller.client;

import com.mvfitness.mytrainer2.dto.ClientFolderDto;
import com.mvfitness.mytrainer2.service.client.ClientFolderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping("/trainer/client-folders")
@RequiredArgsConstructor
public class ClientFolderController {

    private final ClientFolderService svc;

    private static String kc(JwtAuthenticationToken a) { return a.getToken().getSubject(); }

    @GetMapping
    public List<ClientFolderDto> list(JwtAuthenticationToken auth) {
        return svc.list(kc(auth));
    }

    @PostMapping
    public ClientFolderDto create(JwtAuthenticationToken auth, @RequestBody ClientFolderDto dto) {
        return svc.create(kc(auth), dto);
    }

    @PutMapping("/{id}")
    public ClientFolderDto update(
            JwtAuthenticationToken auth,
            @PathVariable Long id,
            @RequestBody ClientFolderDto dto
    ) {
        return svc.update(kc(auth), id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken auth, @PathVariable Long id) {
        svc.delete(kc(auth), id);
        return ResponseEntity.noContent().build();
    }
}
