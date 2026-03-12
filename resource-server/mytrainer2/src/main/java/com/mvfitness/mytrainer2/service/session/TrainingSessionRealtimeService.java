package com.mvfitness.mytrainer2.service.session;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mvfitness.mytrainer2.dto.TrainingSessionDto;
import com.mvfitness.mytrainer2.dto.TrainingSessionRealtimeEventDto;
import com.mvfitness.mytrainer2.dto.WorkoutInstanceExerciseDto;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

@Service
@RequiredArgsConstructor
public class TrainingSessionRealtimeService {

    private final ObjectMapper objectMapper;

    private final Map<Long, Set<WebSocketSession>> sessionsByTrainingSessionId = new ConcurrentHashMap<>();
    private final Map<String, Long> trainingSessionIdBySocketId = new ConcurrentHashMap<>();
    private final Map<String, String> keycloakUserIdBySocketId = new ConcurrentHashMap<>();

    public void register(Long trainingSessionId, WebSocketSession session) {
        sessionsByTrainingSessionId
                .computeIfAbsent(trainingSessionId, ignored -> ConcurrentHashMap.newKeySet())
                .add(session);
        trainingSessionIdBySocketId.put(session.getId(), trainingSessionId);
        Object keycloakUserId = session.getAttributes().get("keycloakUserId");
        if (keycloakUserId instanceof String value) {
            keycloakUserIdBySocketId.put(session.getId(), value);
        }
    }

    public void unregister(WebSocketSession session) {
        Long trainingSessionId = trainingSessionIdBySocketId.remove(session.getId());
        keycloakUserIdBySocketId.remove(session.getId());
        if (trainingSessionId == null) {
            return;
        }
        Set<WebSocketSession> subscribers = sessionsByTrainingSessionId.get(trainingSessionId);
        if (subscribers == null) {
            return;
        }
        subscribers.remove(session);
        if (subscribers.isEmpty()) {
            sessionsByTrainingSessionId.remove(trainingSessionId);
        }
    }

    public void publishSessionUpdated(TrainingSessionDto session) {
        publish(
                session.id(),
                new TrainingSessionRealtimeEventDto(
                        "SESSION_UPDATED",
                        session.id(),
                        session,
                        null
                )
        );
    }

    public void publishInstanceUpdated(Long trainingSessionId,
                                       Function<String, List<WorkoutInstanceExerciseDto>> dataForUser) {
        Set<WebSocketSession> subscribers = sessionsByTrainingSessionId.get(trainingSessionId);
        if (subscribers == null || subscribers.isEmpty()) {
            return;
        }

        for (WebSocketSession session : subscribers) {
            String keycloakUserId = keycloakUserIdBySocketId.get(session.getId());
            if (keycloakUserId == null) {
                unregister(session);
                continue;
            }
            publishToSession(
                    session,
                    new TrainingSessionRealtimeEventDto(
                            "INSTANCE_UPDATED",
                            trainingSessionId,
                            null,
                            dataForUser.apply(keycloakUserId)
                    )
            );
        }
    }

    private void publish(Long trainingSessionId, TrainingSessionRealtimeEventDto event) {
        Set<WebSocketSession> subscribers = sessionsByTrainingSessionId.get(trainingSessionId);
        if (subscribers == null || subscribers.isEmpty()) {
            return;
        }

        for (WebSocketSession session : subscribers) {
            publishToSession(session, event);
        }
    }

    private void publishToSession(WebSocketSession session, TrainingSessionRealtimeEventDto event) {
        if (!session.isOpen()) {
            unregister(session);
            return;
        }

        try {
            String payload = objectMapper.writeValueAsString(event);
            session.sendMessage(new TextMessage(payload));
        } catch (IOException e) {
            unregister(session);
        }
    }
}
