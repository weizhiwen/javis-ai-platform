package com.javis.domain.agent;

import com.javis.domain.common.BaseEntity;
import com.javis.domain.tool.ToolDefinition;

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
@Table(name = "agent_version_tools")
public class AgentVersionTool extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "version_id", nullable = false)
    private AgentVersion version;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tool_id", nullable = false)
    private ToolDefinition tool;

    /** 工具在版本中的排序 */
    @Column(name = "sort_order")
    private Integer sortOrder;

    /** 是否启用该工具 */
    @Column(nullable = false)
    private boolean enabled = true;
}
