package com.mvfitness.mytrainer2.controller.users;

import com.mvfitness.mytrainer2.service.user.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * Used by Keycloak SPI: receives { "kcUserId": "..." } in the body.
     */
    @PostMapping
    public ResponseEntity<String> createUserFromEvent(@RequestBody Map<String, String> payload) {
        return userService.createUserFromEvent(payload);
    }

    /**
     * (optional) keeps your original token-based endpoint if you still need it.
     */
    @PostMapping("/create")
    public ResponseEntity<String> createUserFromToken(@RequestHeader("Authorization") String auth) {
        return userService.createUserFromToken(auth);
    }
}
