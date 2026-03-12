package com.mvfitness.mytrainer2.security;

import com.mvfitness.mytrainer2.service.session.TrainingSessionRealtimeService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
@RequiredArgsConstructor
public class TrainingSessionRealtimeSocketHandler extends TextWebSocketHandler {

    private final TrainingSessionRealtimeService realtimeService;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        Object sessionId = session.getAttributes().get("sessionId");
        if (sessionId instanceof Long id) {
            realtimeService.register(id, session);
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // Server push only.
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        realtimeService.unregister(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        realtimeService.unregister(session);
    }
}
