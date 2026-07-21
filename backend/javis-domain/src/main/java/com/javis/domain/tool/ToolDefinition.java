package com.javis.domain.tool;

import java.util.ArrayList;
import java.util.List;

import com.javis.domain.common.BaseEntity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "tool_definitions")
public class ToolDefinition extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "tool_type", nullable = false)
    private ToolType toolType;

    /** 工具配置列表（如 endpoint, method, headers 等） */
    @OneToMany(mappedBy = "tool", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ToolConfig> configs = new ArrayList<>();

    /** 工具参数定义列表 */
    @OneToMany(mappedBy = "tool", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ToolParameter> parameters = new ArrayList<>();

    @Column(nullable = false)
    private boolean enabled = true;

    public void addConfig(ToolConfig config) {
        this.configs.add(config);
        config.setTool(this);
    }

    public void removeConfig(ToolConfig config) {
        this.configs.remove(config);
        config.setTool(null);
    }

    public void addParameter(ToolParameter parameter) {
        this.parameters.add(parameter);
        parameter.setTool(this);
    }

    public void removeParameter(ToolParameter parameter) {
        this.parameters.remove(parameter);
        parameter.setTool(null);
    }

    public void cascadeSoftDelete() {
        this.softDelete();
        this.configs.forEach(ToolConfig::softDelete);
        this.parameters.forEach(ToolParameter::softDelete);
    }

    public enum ToolType {
        HTTP,
        DATABASE,
        JAVA_METHOD,
        MCP
    }
}
