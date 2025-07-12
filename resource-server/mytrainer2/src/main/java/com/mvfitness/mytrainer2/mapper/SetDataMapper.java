// src/main/java/com/mvfitness/mytrainer2/mapper/SetDataMapper.java
package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.SetData;
import com.mvfitness.mytrainer2.dto.SetDataDto;

public class SetDataMapper {
    public static SetDataDto toDto(SetData e) {
        return new SetDataDto(e.getId(), e.getType(), e.getValue());
    }
}
