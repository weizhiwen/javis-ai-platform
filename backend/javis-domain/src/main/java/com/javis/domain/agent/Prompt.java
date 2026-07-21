package com.javis.domain.agent;

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
@Table(name = "prompts")
public class Prompt extends BaseEntity {

    /** 提示词模板名称 */
    @Column(nullable = false)
    private String name;

    /** 提示词模板内容，支持变量占位符 */
    @Column(name = "template_content", nullable = false, columnDefinition = "TEXT")
    private String templateContent;

    /** 模板描述 */
    @Column private String description;

    /** 关联的 Agent */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agent_id")
    private Agent agent;
}
