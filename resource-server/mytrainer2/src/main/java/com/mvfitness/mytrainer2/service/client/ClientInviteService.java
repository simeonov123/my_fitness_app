package com.mvfitness.mytrainer2.service.client;

import com.mvfitness.mytrainer2.dto.ClientInviteDto;
import com.mvfitness.mytrainer2.dto.ClientInviteValidationDto;
import java.util.List;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

public interface ClientInviteService {

    List<ClientInviteDto> list(String kcUserId, Long clientId);

    ClientInviteDto create(String kcUserId, Long clientId);

    ClientInviteDto regenerate(String kcUserId, Long clientId, Long inviteId);

    ClientInviteDto revoke(String kcUserId, Long clientId, Long inviteId);

    ClientInviteValidationDto validate(String inviteToken);

    ClientInviteValidationDto accept(String inviteToken, JwtAuthenticationToken auth);
}
