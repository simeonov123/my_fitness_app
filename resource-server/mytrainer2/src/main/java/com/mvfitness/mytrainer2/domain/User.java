package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;


@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "users")
@ToString(exclude = {
        "clients", "programs", "programTemplates", "trainingSessions",
        "exercises", "nutritionPlanTemplates", "nutritionPlans",
        "feedbacks", "changeLogs", "userAchievements", "workoutTemplates"
})
@EqualsAndHashCode(onlyExplicitlyIncluded = true, callSuper = false)
public class User extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @Column(name = "keycloak_user_id", nullable = false, unique = true, length = 36)
    private String keycloakUserId;

    @Column(name = "role", length = 50)
    private String role;

    @Column(name = "full_name", length = 100)
    private String fullName;

    @Column(name = "email", length = 100)
    private String email;

    // 1) One User can have many Clients
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Client> clients = new ArrayList<>();

    // 2) One User (trainer) can have many Programs
    @OneToMany(mappedBy = "trainer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Program> programs = new ArrayList<>();

    // 3) One User (trainer) can have many ProgramTemplates
    @OneToMany(mappedBy = "trainer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ProgramTemplate> programTemplates = new ArrayList<>();

    // 4) One User (trainer) can have many TrainingSessions
    @OneToMany(mappedBy = "trainer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<TrainingSession> trainingSessions = new ArrayList<>();

    // 5) One User (trainer) can own multiple Exercises
    @OneToMany(mappedBy = "trainer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Exercise> exercises = new ArrayList<>();

    // 6) One User (trainer) can have many NutritionPlanTemplates
    @OneToMany(mappedBy = "trainer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<NutritionPlanTemplate> nutritionPlanTemplates = new ArrayList<>();

    // 7) One User (trainer) can have many NutritionPlans
    @OneToMany(mappedBy = "trainer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<NutritionPlan> nutritionPlans = new ArrayList<>();

    // 8) One User can give multiple Feedbacks
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Feedback> feedbacks = new ArrayList<>();

    // 9) One User can appear in many ChangeLogs
    @OneToMany(mappedBy = "changedByUser", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ChangeLog> changeLogs = new ArrayList<>();

    // 10) One User can have many UserAchievements
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<UserAchievement> userAchievements = new ArrayList<>();

    // 11) One User (trainer) can have many WorkoutTemplates
    @OneToMany(mappedBy = "trainer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<WorkoutTemplate> workoutTemplates = new ArrayList<>();

    @OneToMany(mappedBy = "trainer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<TrainerClients> trainerClients = new ArrayList<>();
    // (No timestamps here; now inherited from BaseTimestampedEntity)
}
