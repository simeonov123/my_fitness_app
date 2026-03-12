package com.mvfitness.mytrainer2.controller.client;

import com.mvfitness.mytrainer2.dto.ClientInviteValidationDto;
import com.mvfitness.mytrainer2.service.client.ClientInviteService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/public/client-invites")
@RequiredArgsConstructor
public class PublicClientInviteController {

    private final ClientInviteService service;

    @GetMapping("/{token}")
    public ClientInviteValidationDto validate(@PathVariable String token) {
        return service.validate(token);
    }

    @PostMapping("/{token}/accept")
    public ClientInviteValidationDto accept(
            @PathVariable String token,
            JwtAuthenticationToken auth
    ) {
        return service.accept(token, auth);
    }
}
