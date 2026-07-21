package com.javis.domain.agent;

import com.javis.domain.common.BaseEntity;
import com.javis.domain.knowledge.KnowledgeBase;

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
@Table(name = "agent_version_knowledge_bases")
public class AgentVersionKnowledgeBase extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "version_id", nullable = false)
    private AgentVersion version;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "knowledge_base_id", nullable = false)
    private KnowledgeBase knowledgeBase;

    /** 检索时返回的最大文档数 */
    @Column(name = "top_k")
    private Integer topK = 5;

    /** 相似度阈值 */
    @Column(name = "similarity_threshold")
    private Double similarityThreshold = 0.7;

    /** 排序 */
    @Column(name = "sort_order")
    private Integer sortOrder;
}
