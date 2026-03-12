package com.mvfitness.mytrainer2.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {

    private final TrainingSessionRealtimeSocketHandler socketHandler;
    private final TrainingSessionWebSocketAuthInterceptor authInterceptor;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(socketHandler, "/ws/training-sessions/{sessionId}")
                .addInterceptors(authInterceptor)
                .setAllowedOriginPatterns("*");
    }
}
