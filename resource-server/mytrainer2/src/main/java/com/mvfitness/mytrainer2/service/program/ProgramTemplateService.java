package com.mvfitness.mytrainer2.service.program;

import com.mvfitness.mytrainer2.dto.ClientProgramDto;
import com.mvfitness.mytrainer2.dto.ProgramAssignmentRequestDto;
import com.mvfitness.mytrainer2.dto.ProgramTemplateDto;
import com.mvfitness.mytrainer2.dto.TrainingSessionDto;

import java.util.List;

public interface ProgramTemplateService {
    List<ProgramTemplateDto> listTemplates(String kcUserId);
    ProgramTemplateDto getTemplate(String kcUserId, Long id);
    ProgramTemplateDto createTemplate(String kcUserId, ProgramTemplateDto dto);
    ProgramTemplateDto updateTemplate(String kcUserId, Long id, ProgramTemplateDto dto);
    void deleteTemplate(String kcUserId, Long id);
    void assignTemplate(String kcUserId, Long id, ProgramAssignmentRequestDto dto);
    List<ClientProgramDto> listClientPrograms(String kcUserId);
    List<ClientProgramDto> listTrainerAssignedPrograms(String kcUserId);
    TrainingSessionDto startProgramDayForClient(String kcUserId, Long assignmentId, Integer dayIndex);
    TrainingSessionDto startProgramDayForTrainer(String kcUserId, Long assignmentId, Integer dayIndex);
}
