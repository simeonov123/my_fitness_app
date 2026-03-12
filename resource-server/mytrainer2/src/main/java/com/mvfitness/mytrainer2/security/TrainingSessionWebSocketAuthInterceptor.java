package com.mvfitness.mytrainer2.security;

import com.mvfitness.mytrainer2.service.session.TrainingSessionAccessService;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

@Component
@RequiredArgsConstructor
public class TrainingSessionWebSocketAuthInterceptor implements HandshakeInterceptor {

    private final JwtDecoder jwtDecoder;
    private final TrainingSessionAccessService accessService;

    @Override
    public boolean beforeHandshake(ServerHttpRequest request,
                                   ServerHttpResponse response,
                                   WebSocketHandler wsHandler,
                                   Map<String, Object> attributes) {
        URI uri = request.getURI();
        String token = queryParam(uri, "token");
        Long sessionId = sessionId(uri.getPath());
        if (token == null || sessionId == null) {
            return false;
        }

        try {
            Jwt jwt = jwtDecoder.decode(token);
            String keycloakUserId = jwt.getSubject();
            if (!accessService.canAccess(keycloakUserId, sessionId)) {
                return false;
            }
            attributes.put("sessionId", sessionId);
            attributes.put("keycloakUserId", keycloakUserId);
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    @Override
    public void afterHandshake(ServerHttpRequest request,
                               ServerHttpResponse response,
                               WebSocketHandler wsHandler,
                               Exception exception) {
    }

    private String queryParam(URI uri, String key) {
        String query = uri.getRawQuery();
        if (query == null || query.isBlank()) {
            return null;
        }
        for (String pair : query.split("&")) {
            String[] parts = pair.split("=", 2);
            if (parts.length == 2 && key.equals(parts[0])) {
                return URLDecoder.decode(parts[1], StandardCharsets.UTF_8);
            }
        }
        return null;
    }

    private Long sessionId(String path) {
        if (path == null || path.isBlank()) {
            return null;
        }
        String[] parts = path.split("/");
        if (parts.length == 0) {
            return null;
        }
        try {
            return Long.parseLong(parts[parts.length - 1]);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
