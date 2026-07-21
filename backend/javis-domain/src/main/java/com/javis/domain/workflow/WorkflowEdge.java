package com.javis.domain.workflow;

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
@Table(name = "workflow_edges")
public class WorkflowEdge extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workflow_id", nullable = false)
    private WorkflowDefinition workflow;

    @Column(name = "source_node_key", nullable = false)
    private String sourceNodeKey;

    @Column(name = "target_node_key", nullable = false)
    private String targetNodeKey;

    /** 条件分支表达式（可选，用于 CONDITION 类型节点） */
    @Column(name = "condition_expression")
    private String conditionExpression;

    /** 边标签 */
    @Column private String label;
}
