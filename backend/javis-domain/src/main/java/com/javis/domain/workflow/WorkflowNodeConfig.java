package com.javis.domain.workflow;

import java.util.Map;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkflowNodeConfig {

    /** Agent 节点：关联的 agentId */
    private String agentId;

    /** LLM 节点：关联的 modelId */
    private String modelId;

    /** LLM 节点：温度参数 */
    private Double temperature;

    /** Tool 节点：关联的 toolId */
    private String toolId;

    /** Condition 节点：条件表达式 */
    private String conditionExpression;

    /** 扩展属性 */
    private Map<String, Object> properties;
}
