package com.javis.domain.knowledge;

import com.fasterxml.jackson.core.type.TypeReference;
import com.javis.domain.common.JsonbConverter;

import jakarta.persistence.Converter;

@Converter(autoApply = false)
public class DocumentMetadataConverter extends JsonbConverter<DocumentMetadata> {

    @Override
    protected TypeReference<DocumentMetadata> typeReference() {
        return new TypeReference<>() {};
    }
}
