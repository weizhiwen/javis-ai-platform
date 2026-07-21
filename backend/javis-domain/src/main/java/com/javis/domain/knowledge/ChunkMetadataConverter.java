package com.javis.domain.knowledge;

import com.fasterxml.jackson.core.type.TypeReference;
import com.javis.domain.common.JsonbConverter;

import jakarta.persistence.Converter;

@Converter(autoApply = false)
public class ChunkMetadataConverter extends JsonbConverter<ChunkMetadata> {

    @Override
    protected TypeReference<ChunkMetadata> typeReference() {
        return new TypeReference<>() {};
    }
}
