package com.javis.domain.tool;

import com.javis.domain.common.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "tool_configs")
public class ToolConfig extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tool_id", nullable = false)
    private ToolDefinition tool;

    /** 配置键，如 endpoint, method, headers, timeout 等 */
    @Column(name = "config_key", nullable = false)
    private String configKey;

    /** 配置值 */
    @Column(name = "config_value", columnDefinition = "TEXT")
    private String configValue;
}
