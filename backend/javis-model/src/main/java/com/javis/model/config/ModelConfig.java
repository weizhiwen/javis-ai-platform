package com.javis.model.config;

import com.javis.domain.common.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "ai_models")
public class ModelConfig extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column(name = "model_id", nullable = false)
    private String modelId;

    @Enumerated(EnumType.STRING)
    @Column(name = "provider", nullable = false)
    private ModelProvider provider;

    @Column private String apiKey;

    @Column(name = "base_url")
    private String baseUrl;

    @Column(nullable = false)
    private boolean enabled = true;

    @Column private String description;
}
