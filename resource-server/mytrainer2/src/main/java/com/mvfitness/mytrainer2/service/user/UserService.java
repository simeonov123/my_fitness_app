package com.mvfitness.mytrainer2.service.user;

import org.springframework.http.ResponseEntity;

import java.util.Map;

public interface UserService {
    ResponseEntity<String> createUserFromToken(String authorizationHeader);
    ResponseEntity<String> createUserFromEvent(Map<String, String> payload);
}
