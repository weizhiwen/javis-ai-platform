package com.javis.domain.common;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import jakarta.persistence.AttributeConverter;

public abstract class JsonbConverter<T> implements AttributeConverter<T, String> {

    protected static final ObjectMapper MAPPER =
            new ObjectMapper().registerModule(new JavaTimeModule());

    protected abstract TypeReference<T> typeReference();

    @Override
    public String convertToDatabaseColumn(T attribute) {
        if (attribute == null) {
            return null;
        }
        try {
            return MAPPER.writeValueAsString(attribute);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Failed to serialize to JSON", e);
        }
    }

    @Override
    public T convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return null;
        }
        try {
            return MAPPER.readValue(dbData, typeReference());
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Failed to deserialize from JSON", e);
        }
    }
}
