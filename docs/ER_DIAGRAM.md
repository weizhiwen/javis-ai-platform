# javis-domain E-R Diagram

> 生成日期: 2026-07-21
> 实体总数: 20 个 (+ 2 个中间表)
> 所有实体继承 `BaseEntity` (id, created_at, updated_at, deleted)

```mermaid
erDiagram
    %% ====================================================================
    %% 权限体系
    %% ====================================================================
    User {
        UUID id PK
        String username UK
        String email UK
        String password
        String display_name
        String avatar
        boolean enabled
    }

    Role {
        UUID id PK
        String code UK
        String name
        String description
    }

    Permission {
        UUID id PK
        String code UK
        String name
        String description
        ResourceType resource_type
    }

    User }o--o{ Role : "user_roles"
    Role }o--o{ Permission : "role_permissions"

    %% ====================================================================
    %% AI 模型
    %% ====================================================================
    AiModel {
        UUID id PK
        String name
        String model_id
        ModelProvider provider
        String api_key
        String base_url
        boolean enabled
        String description
    }

    %% ====================================================================
    %% 工具系统
    %% ====================================================================
    ToolDefinition {
        UUID id PK
        String name
        String description
        ToolType tool_type
        boolean enabled
    }

    ToolConfig {
        UUID id PK
        String config_key
        String config_value
    }

    ToolParameter {
        UUID id PK
        String name
        String param_type
        String description
        boolean required
        String default_value
        Integer sort_order
    }

    ToolDefinition ||--o{ ToolConfig : "configs"
    ToolDefinition ||--o{ ToolParameter : "parameters"

    %% ====================================================================
    %% Agent + 版本管理
    %% ====================================================================
    Agent {
        UUID id PK
        String name
        String description
        String avatar_url
    }

    AgentVersion {
        UUID id PK
        String version
        VersionStatus status
        String system_prompt
    }

    Prompt {
        UUID id PK
        String name
        String template_content
        String description
    }

    AgentVersionTool {
        UUID id PK
        Integer sort_order
        boolean enabled
    }

    AgentVersionKnowledgeBase {
        UUID id PK
        Integer top_k
        Double similarity_threshold
        Integer sort_order
    }

    Agent ||--o| AgentVersion : "currentVersion"
    Agent ||--o{ AgentVersion : "versions"
    Agent ||--o{ Prompt : "prompts"
    AgentVersion ||--o{ AgentVersionTool : "tools"
    AgentVersion ||--o{ AgentVersionKnowledgeBase : "knowledgeBases"

    %% ====================================================================
    %% 知识库
    %% ====================================================================
    KnowledgeBase {
        UUID id PK
        String name
        String description
        Integer chunk_size
        Integer chunk_overlap
        Integer document_count
    }

    Document {
        UUID id PK
        String name
        String file_path
        Long file_size
        String mime_type
        DocumentStatus status
        Integer chunk_count
        JSONB metadata
    }

    Chunk {
        UUID id PK
        String content
        Integer chunk_index
        Integer token_count
        vector embedding_vector
        JSONB metadata
    }

    KnowledgeBase ||--o{ Document : "documents"
    Document ||--o{ Chunk : "chunks"
    KnowledgeBase ||--o{ Chunk : "chunks (denormalized)"

    %% ====================================================================
    %% 对话
    %% ====================================================================
    Conversation {
        UUID id PK
        String title
        String last_message_preview
        Instant last_message_at
    }

    Message {
        UUID id PK
        MessageRole role
        String content
        Integer token_count
        UUID parent_message_id
    }

    Conversation ||--o{ Message : "messages"

    %% ====================================================================
    %% 工作流
    %% ====================================================================
    WorkflowDefinition {
        UUID id PK
        String name
        String description
        boolean published
        String version
    }

    WorkflowNode {
        UUID id PK
        String node_key
        NodeType node_type
        JSONB config
        Integer position_x
        Integer position_y
    }

    WorkflowEdge {
        UUID id PK
        String source_node_key
        String target_node_key
        String condition_expression
        String label
    }

    WorkflowDefinition ||--o{ WorkflowNode : "nodes"
    WorkflowDefinition ||--o{ WorkflowEdge : "edges"

    %% ====================================================================
    %% 跨域关联
    %% ====================================================================
    Agent }o--|| User : "creator"
    AgentVersion }o--o| AiModel : "model"
    AgentVersionTool }o--|| ToolDefinition : "tool"
    AgentVersionKnowledgeBase }o--|| KnowledgeBase : "knowledgeBase"
    KnowledgeBase }o--|| User : "creator"
    KnowledgeBase }o--o| AiModel : "embeddingModel"
    Conversation }o--|| Agent : "agent"
    Conversation }o--|| User : "user"
    Conversation }o--o| AiModel : "model"
    WorkflowDefinition }o--|| User : "creator"
```

## 关联关系汇总

| 关系 | 类型 | 说明 |
|------|------|------|
| User ↔ Role | ManyToMany | 中间表 `user_roles` |
| Role ↔ Permission | ManyToMany | 中间表 `role_permissions` |
| Agent → User | ManyToOne | creator |
| Agent → AgentVersion | OneToOne | currentVersion (循环 FK) |
| Agent → AgentVersion | OneToMany | versions |
| AgentVersion → Agent | ManyToOne | agent |
| AgentVersion → AiModel | ManyToOne | model |
| AgentVersionTool → AgentVersion | ManyToOne | version |
| AgentVersionTool → ToolDefinition | ManyToOne | tool |
| AgentVersionKnowledgeBase → AgentVersion | ManyToOne | version |
| AgentVersionKnowledgeBase → KnowledgeBase | ManyToOne | knowledgeBase |
| Prompt → Agent | ManyToOne | agent |
| ToolDefinition → ToolConfig | OneToMany | configs |
| ToolDefinition → ToolParameter | OneToMany | parameters |
| KnowledgeBase → User | ManyToOne | creator |
| KnowledgeBase → AiModel | ManyToOne | embeddingModel |
| Document → KnowledgeBase | ManyToOne | knowledgeBase |
| Chunk → Document | ManyToOne | document |
| Chunk → KnowledgeBase | ManyToOne | knowledgeBase (冗余) |
| Conversation → Agent | ManyToOne | agent |
| Conversation → User | ManyToOne | user |
| Conversation → AiModel | ManyToOne | model |
| Message → Conversation | ManyToOne | conversation |
| WorkflowDefinition → User | ManyToOne | creator |
| WorkflowNode → WorkflowDefinition | ManyToOne | workflow |
| WorkflowEdge → WorkflowDefinition | ManyToOne | workflow |
