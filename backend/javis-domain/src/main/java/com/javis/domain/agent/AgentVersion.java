package com.javis.domain.agent;

import java.util.ArrayList;
import java.util.List;

import com.javis.domain.common.BaseEntity;
import com.javis.domain.model.AiModel;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "agent_versions")
public class AgentVersion extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agent_id", nullable = false)
    private Agent agent;

    /** 语义版本号，DRAFT 为 "0.0.0"，发布后如 "1.0.0" */
    @Column(nullable = false)
    private String version = "0.0.0";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VersionStatus status = VersionStatus.DRAFT;

    /** 系统提示词 */
    @Column(name = "system_prompt", columnDefinition = "TEXT")
    private String systemPrompt;

    /** 关联的 AI 模型 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "model_id")
    private AiModel model;

    /** 版本绑定的工具列表 */
    @OneToMany(mappedBy = "version", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AgentVersionTool> tools = new ArrayList<>();

    /** 版本关联的知识库列表 */
    @OneToMany(mappedBy = "version", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AgentVersionKnowledgeBase> knowledgeBases = new ArrayList<>();

    public void addTool(AgentVersionTool tool) {
        this.tools.add(tool);
        tool.setVersion(this);
    }

    public void removeTool(AgentVersionTool tool) {
        this.tools.remove(tool);
        tool.setVersion(null);
    }

    public void addKnowledgeBase(AgentVersionKnowledgeBase kb) {
        this.knowledgeBases.add(kb);
        kb.setVersion(this);
    }

    public void removeKnowledgeBase(AgentVersionKnowledgeBase kb) {
        this.knowledgeBases.remove(kb);
        kb.setVersion(null);
    }

    public void publish(String newVersion) {
        this.status = VersionStatus.PUBLISHED;
        this.version = newVersion;
    }

    public void cascadeSoftDelete() {
        this.softDelete();
        this.tools.forEach(AgentVersionTool::softDelete);
        this.knowledgeBases.forEach(AgentVersionKnowledgeBase::softDelete);
    }

    public enum VersionStatus {
        DRAFT,
        PUBLISHED,
        ARCHIVED
    }
}
