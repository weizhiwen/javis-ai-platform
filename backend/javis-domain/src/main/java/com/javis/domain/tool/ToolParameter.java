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
@Table(name = "tool_parameters")
public class ToolParameter extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tool_id", nullable = false)
    private ToolDefinition tool;

    /** 参数名称 */
    @Column(nullable = false)
    private String name;

    /** 参数类型：string, number, boolean, object, array */
    @Column(name = "param_type", nullable = false)
    private String paramType;

    /** 参数描述 */
    @Column private String description;

    /** 是否必填 */
    @Column(nullable = false)
    private boolean required = false;

    /** 默认值 */
    @Column(name = "default_value")
    private String defaultValue;

    /** 排序 */
    @Column(name = "sort_order")
    private Integer sortOrder;
}
