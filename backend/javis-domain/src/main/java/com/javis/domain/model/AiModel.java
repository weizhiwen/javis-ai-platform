package com.javis.domain.model;

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
public class AiModel extends BaseEntity {

    /** 显示名称，如 "GPT-4o" */
    @Column(nullable = false)
    private String name;

    /** 模型标识符，调用 API 时传给 provider，如 "gpt-4o-2024-08-06" */
    @Column(name = "model_id", nullable = false)
    private String modelId;

    /** 模型提供商 */
    @Enumerated(EnumType.STRING)
    @Column(name = "provider", nullable = false)
    private ModelProvider provider;

    /** API 密钥，用于认证 */
    @Column private String apiKey;

    /** API 基础地址，用于自定义或私有部署 */
    @Column(name = "base_url")
    private String baseUrl;

    /** 是否启用 */
    @Column(nullable = false)
    private boolean enabled = true;

    /** 模型描述 */
    @Column private String description;

    public enum ModelProvider {
        OPENAI,
        DEEPSEEK,
        QWEN,
        CLAUDE,
        GEMINI,
        OLLAMA
    }
}
