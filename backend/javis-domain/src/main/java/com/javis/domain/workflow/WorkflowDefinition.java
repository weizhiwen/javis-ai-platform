package com.javis.domain.workflow;

import java.util.ArrayList;
import java.util.List;

import com.javis.domain.common.BaseEntity;
import com.javis.domain.user.User;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
@Table(name = "workflow_definitions")
public class WorkflowDefinition extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id")
    private User creator;

    @Column(nullable = false)
    private boolean published = false;

    @Column private String version;

    /** 工作流节点列表 */
    @OneToMany(mappedBy = "workflow", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<WorkflowNode> nodes = new ArrayList<>();

    /** 工作流边列表 */
    @OneToMany(mappedBy = "workflow", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<WorkflowEdge> edges = new ArrayList<>();

    public void addNode(WorkflowNode node) {
        this.nodes.add(node);
        node.setWorkflow(this);
    }

    public void removeNode(WorkflowNode node) {
        this.nodes.remove(node);
        node.setWorkflow(null);
    }

    public void addEdge(WorkflowEdge edge) {
        this.edges.add(edge);
        edge.setWorkflow(this);
    }

    public void removeEdge(WorkflowEdge edge) {
        this.edges.remove(edge);
        edge.setWorkflow(null);
    }

    public void cascadeSoftDelete() {
        this.softDelete();
        this.nodes.forEach(WorkflowNode::softDelete);
        this.edges.forEach(WorkflowEdge::softDelete);
    }
}
