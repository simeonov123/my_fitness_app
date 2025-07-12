package com.mvfitness.mytrainer2.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "training_sessions")
public class TrainingSession extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /* —— owning trainer ——————————————————————————————— */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trainer_id", nullable = false)
    private User trainer;

    /* —— NEW: many-to-many clients ———————————————————— */
    @Builder.Default
    @ManyToMany
    @JoinTable(
            name = "training_session_clients",
            joinColumns = @JoinColumn(name = "training_session_id"),
            inverseJoinColumns = @JoinColumn(name = "client_id")
    )
    private List<Client> clients = new ArrayList<>();

    /* —— links to other structures ———————————————— */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "microcycle_id")
    private Microcycle microcycle;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_template_id")
    private WorkoutTemplate workoutTemplate;

    /* —— scheduling / meta ——————————————————————————— */
  @Column(name = "start_time", nullable = false)
   private LocalDateTime startTime;
    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;    private Integer       dayIndexInCycle;

    @Column(length = 100)   private String sessionName;
    @Column(columnDefinition = "TEXT") private String sessionDescription;
    @Column(length = 50)    private String sessionType;
    @Column(columnDefinition = "TEXT") private String trainerNotes;
    @Column(columnDefinition = "TEXT") private String clientFeedback;
    @Column(length = 50)    private String status;
    private Boolean         isCompleted;

    /* —— workout instances ——————————————————————————— */
    @Builder.Default
    @OneToMany(mappedBy = "trainingSession",
            cascade = CascadeType.ALL,
            orphanRemoval = true)
    private List<WorkoutInstance> workoutInstances = new ArrayList<>();
}
