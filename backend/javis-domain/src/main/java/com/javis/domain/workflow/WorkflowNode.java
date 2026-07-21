package com.javis.domain.workflow;

import com.javis.domain.common.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "workflow_nodes")
public class WorkflowNode extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workflow_id", nullable = false)
    private WorkflowDefinition workflow;

    @Column(name = "node_key", nullable = false)
    private String nodeKey;

    @Enumerated(EnumType.STRING)
    @Column(name = "node_type", nullable = false)
    private NodeType nodeType;

    /** 节点配置，不同类型节点有不同的配置结构 */
    @Convert(converter = WorkflowNodeConfigConverter.class)
    @Column(name = "config_json", columnDefinition = "jsonb")
    private WorkflowNodeConfig config;

    @Column(name = "position_x")
    private Integer positionX;

    @Column(name = "position_y")
    private Integer positionY;

    public enum NodeType {
        START,
        AGENT,
        LLM,
        TOOL,
        CONDITION,
        END
    }
}
