package com.mvfitness.mytrainer2.service.user;

import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;

    @Override
    public ResponseEntity<String> createUserFromToken(String authorizationHeader) {
        try {
            // 1) Extract token
            if (!authorizationHeader.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body("Invalid Authorization header.");
            }
            String token = authorizationHeader.substring(7);

            // 2) Decode token (no signature check here, just decode)
            DecodedJWT decoded = JWT.decode(token);

            // 3) Extract user data
            String keycloakUserId = decoded.getSubject(); // or custom claim if you set it
            String fullName = decoded.getClaim("name").asString();
            String email = decoded.getClaim("email").asString();

            // 4) Extract roles from realm_access
            Map<String, Object> realmAccessMap = decoded.getClaim("realm_access").asMap();
            List<String> roles = realmAccessMap != null && realmAccessMap.containsKey("roles")
                    ? (List<String>) realmAccessMap.get("roles")
                    : List.of();

            String role = roles.contains("TRAINER")
                    ? "TRAINER"
                    : roles.contains("CLIENT")
                    ? "CLIENT"
                    : "USER"; // fallback

            // 5) Build and save the user
            // Check if user already exists

            User existingUser = userRepository.findByKeycloakUserId(keycloakUserId);
            if (existingUser != null) {
                return ResponseEntity.badRequest()
                        .body("User with Keycloak ID already exists: " + keycloakUserId);
            }
            // Create new user
            User newUser = User.builder()
                    .keycloakUserId(keycloakUserId)
                    .fullName(fullName)
                    .email(email)
                    .role(role)
                    .build();

            userRepository.save(newUser);

            return ResponseEntity.ok("User created/updated with Keycloak ID: " + keycloakUserId);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Failed to parse/handle token: " + e.getMessage());
        }
    }

    @Override
    public ResponseEntity<String> createUserFromEvent(Map<String, String> payload) {
        try {
            String keycloakUserId = payload.get("kcUserId");
            if (keycloakUserId == null || keycloakUserId.isBlank()) {
                return ResponseEntity.badRequest().body("Missing kcUserId");
            }

            // Prevent duplicates
            if (userRepository.findByKeycloakUserId(keycloakUserId) != null) {
                return ResponseEntity
                        .status(HttpStatus.CONFLICT)
                        .body("User already exists: " + keycloakUserId);
            }

            // Create minimal User record. You can extend with more fields if payload includes them.
            User newUser = User.builder()
                    .keycloakUserId(keycloakUserId)
                    .build();

            userRepository.save(newUser);
            return ResponseEntity.ok("User created with Keycloak ID: " + keycloakUserId);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error creating user: " + e.getMessage());
        }
    }
}
