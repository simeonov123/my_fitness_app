package com.mvfitness.mytrainer2.controller.client;

import com.mvfitness.mytrainer2.dto.ClientInviteDto;
import com.mvfitness.mytrainer2.service.client.ClientInviteService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping("/trainer/clients/{clientId}/invites")
@RequiredArgsConstructor
public class ClientInviteController {

    private final ClientInviteService service;

    private static String kcUserId(JwtAuthenticationToken auth) {
        return auth.getToken().getSubject();
    }

    @GetMapping
    public List<ClientInviteDto> list(
            JwtAuthenticationToken auth,
            @PathVariable Long clientId
    ) {
        return service.list(kcUserId(auth), clientId);
    }

    @PostMapping
    public ClientInviteDto create(
            JwtAuthenticationToken auth,
            @PathVariable Long clientId
    ) {
        return service.create(kcUserId(auth), clientId);
    }

    @PostMapping("/{inviteId}/regenerate")
    public ClientInviteDto regenerate(
            JwtAuthenticationToken auth,
            @PathVariable Long clientId,
            @PathVariable Long inviteId
    ) {
        return service.regenerate(kcUserId(auth), clientId, inviteId);
    }

    @PostMapping("/{inviteId}/revoke")
    public ClientInviteDto revoke(
            JwtAuthenticationToken auth,
            @PathVariable Long clientId,
            @PathVariable Long inviteId
    ) {
        return service.revoke(kcUserId(auth), clientId, inviteId);
    }
}
