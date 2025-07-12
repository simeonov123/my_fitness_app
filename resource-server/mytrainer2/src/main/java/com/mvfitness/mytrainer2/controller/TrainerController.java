package com.mvfitness.mytrainer2.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/trainer")
public class TrainerController {

    // only a user whose token includes ROLE_TRAINER can call
    @PreAuthorize("hasRole('TRAINER')")
    @GetMapping("/dashboard")
    public String trainerDashboard() {
        return "Hello Trainer!";
    }
}
