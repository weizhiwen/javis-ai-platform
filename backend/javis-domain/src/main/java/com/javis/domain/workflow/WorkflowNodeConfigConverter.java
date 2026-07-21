package com.javis.domain.workflow;

import com.fasterxml.jackson.core.type.TypeReference;
import com.javis.domain.common.JsonbConverter;

import jakarta.persistence.Converter;

@Converter(autoApply = false)
public class WorkflowNodeConfigConverter extends JsonbConverter<WorkflowNodeConfig> {

    @Override
    protected TypeReference<WorkflowNodeConfig> typeReference() {
        return new TypeReference<>() {};
    }
}
