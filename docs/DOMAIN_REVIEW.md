# javis-domain 领域模型审查报告

> 审查日期: 2025-07-20
> 更新日期: 2026-07-21 (标注已修复项)
> 审查范围: `javis-domain` 模块下所有 Entity + `V1__init_schema.sql`

---

## P0 — 必须修复

### 1. 权限模型缺少多对多关联关系

**文件**: `User.java`, `Role.java`, `Permission.java`, `V1__init_schema.sql`

`User`、`Role`、`Permission` 三个 Entity 之间没有任何 JPA 关联注解，数据库中也没有 `user_roles` 和 `role_permissions` 中间表。企业级权限体系无法运作。

**当前代码**:
```java
// User.java — 没有 roles 集合
@Entity @Table(name = "users")
public class User extends BaseEntity { ... }

// Role.java — 没有 users / permissions 集合
@Entity @Table(name = "roles")
public class Role extends BaseEntity { ... }

// Permission.java — 没有 roles 集合
@Entity @Table(name = "permissions")
public class Permission extends BaseEntity { ... }
```

**需要补充的关联关系**:
```
User ──< UserRole >── Role ──< RolePermission >── Permission
```

需要新增 `UserRole` 和 `RolePermission` 两个中间实体（或直接用 `@ManyToMany` + `@JoinTable`），并在 `User` / `Role` 中声明集合属性。

---

### 2. Message.parentMessageId 类型不一致

**文件**: `Message.java`

消息主键是 `UUID`，但 `parentMessageId` 却是 `String` 类型，类型不匹配。此外用字符串无法享受 JPA 的外键约束和关联查询能力。

**当前代码**:
```java
@Column(name = "parent_message_id")
private String parentMessageId;
```

**建议改为**:
```java
// 方案A: 自关联 ManyToOne
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "parent_message_id")
private Message parentMessage;

// 方案B: 至少修正类型
@Column(name = "parent_message_id")
private UUID parentMessageId;
```

---

## P1 — 高优先级

### 3. Agent 工具/知识库关联塞入 JSON，缺失显式领域关系

**文件**: `Agent.java`, `KnowledgeBase.java`, `ToolDefinition.java`

Agent 的工具绑定（ToolDefinition）和知识库关联（KnowledgeBase）全部塞进 `configJson` 字段中，没有使用 JPA 多对多关联。这导致：
- 无法做外键约束
- 无法通过 JPA 进行关联查询
- 领域语义丢失，代码可读性差
- JSON 内部格式变更无编译期检查

**当前代码**:
```java
@Column(name = "config_json", columnDefinition = "jsonb")
private String configJson;  // 工具绑定、知识库关联等都在这里
```

**建议**:
```java
// Agent.java 中增加显式关联
@ManyToMany
@JoinTable(
    name = "agent_tools",
    joinColumns = @JoinColumn(name = "agent_id"),
    inverseJoinColumns = @JoinColumn(name = "tool_id")
)
private Set<ToolDefinition> tools;

@ManyToMany
@JoinTable(
    name = "agent_knowledge_bases",
    joinColumns = @JoinColumn(name = "agent_id"),
    inverseJoinColumns = @JoinColumn(name = "knowledge_base_id")
)
private Set<KnowledgeBase> knowledgeBases;
```

同时需要在数据库中新增 `agent_tools` 和 `agent_knowledge_bases` 中间表。`configJson` 字段可以保留用于存放其他非结构化配置。

---

### 4. AiModel 明文存储 API Key — 已修复

**原文件**: `AiModel.java` (已移至 `javis-model` 模块，重命名为 `ModelConfig.java`)

API 密钥以明文形式存储的问题仍存在，但已通过架构重构明确了职责边界：
- `ModelConfig` 现在位于 `javis-model` 模块（基础设施层）
- `javis-domain` 不再直接持有 API Key 等敏感技术细节

**待处理**: 仍需实现 API Key 加密存储方案（数据库级加密或外部密钥服务）。

---

### 5. 工作流缺少 Edge（边）表，DAG 不完整

**文件**: `WorkflowDefinition.java`, `WorkflowNode.java`, `V1__init_schema.sql`

当前有 `WorkflowNode` 表存储节点，但**完全没有边的概念**——没有 `workflow_edges` 表。DAG 图结构中的连线关系是工作流引擎的核心，目前缺失。

**建议新增**:

```java
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
    @Column
    private String label;
}
```

---

## P2 — 中优先级

### 6. Permission.resourceType 缺乏枚举约束

**文件**: `Permission.java`

```java
@Column(name = "resource_type")
private String resourceType;  // 目前初始化数据中用了 'agent'
```

自由文本字段容易拼写错误，`'agent'`、`'Agent'`、`'agents'` 都会被当作不同值。

**建议改为枚举**:
```java
@Enumerated(EnumType.STRING)
@Column(name = "resource_type")
private ResourceType resourceType;

public enum ResourceType {
    AGENT, KNOWLEDGE, WORKFLOW, MODEL, TOOL, CHAT, SYSTEM
}
```

---

### 7. Agent.modelId 使用 String 而非关联 AiModel — 已修复

**原问题**: domain 实体直接引用 `AiModel` 实体，违反了 domain 与 model 的职责边界。

**修复方案**: 通过架构重构，`AiModel` 已移至 `javis-model` 模块（重命名为 `ModelConfig`），domain 实体改用 UUID 引用：
- `AgentVersion.modelId` (UUID) — 引用 ModelConfig
- `Conversation.modelId` (UUID) — 引用 ModelConfig
- `KnowledgeBase.embeddingModelId` (UUID) — 引用 ModelConfig

这样 domain 层不感知 AI 技术细节，符合 DDD 原则。

---

## P3 — 低优先级 / 优化建议

### 8. Conversation 缺少最后消息预览字段

**文件**: `Conversation.java`

对话列表页通常需要展示最后一条消息的摘要。当前需要通过 JOIN messages 表或子查询获取，在大列表场景下效率低。

**建议**:
```java
/** 最后一条消息的预览文本（冗余字段，用于列表展示） */
@Column(name = "last_message_preview", length = 200)
private String lastMessagePreview;

/** 最后一条消息的时间 */
@Column(name = "last_message_at")
private Instant lastMessageAt;
```

可通过领域事件（Domain Event）在发送消息时更新。

---

### 9. Conversation 的 modelId 是否冗余 — 已修复

**文件**: `Conversation.java`

已改为 UUID 类型并添加注释说明意图：

```java
/** 覆盖 Agent 默认模型 ID，为空则使用 Agent 当前版本的模型 */
@Column(name = "model_id")
private UUID modelId;
```

---

### 10. Chunk 冗余关联 KnowledgeBase

**文件**: `Chunk.java`

```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "knowledge_base_id", nullable = false)
private KnowledgeBase knowledgeBase;
```

通过 `chunk → document → knowledge_base` 即可导航到 KnowledgeBase。这里的冗余关联主要是为了向量检索时直接过滤 `knowledge_base_id` 避免 JOIN。

**建议**：保留冗余以优化性能，但需要增加数据库约束或应用层校验确保 `chunk.knowledge_base_id` 与 `document.knowledge_base_id` 一致。

---

### 11. WorkflowNode.positionX/Y 精度过大

**文件**: `WorkflowNode.java`

```java
@Column(name = "position_x")
private Double positionX;  // Canvas 坐标使用 Double 精度过剩
```

Canvas 坐标用 `Integer` 或 `Float` 就足够了。

---

### 12. BaseEntity 的 @SQLRestriction 潜在陷阱

**文件**: `BaseEntity.java`

```java
@SQLRestriction("deleted = false")
```

这个注解作用于所有查询（包括关联查询），优点是自动过滤已删除数据，缺点是：
- 某些后台管理场景需要查看已删除数据时，需要写 native query
- 关联查询中如果关联表也软删除，可能产生难以排查的过滤行为
- `COUNT(*)` 等聚合可能因为自动过滤导致结果与预期不符

**建议**: 在 `BaseRepository` 中提供 `findAllIncludingDeleted()` 等方法，确保管理端可用。

---

## 汇总

| 优先级 | # | 问题 | 模块 | 修复难度 |
|--------|---|------|------|----------|
| P0 | 1 | 权限模型缺中间关联表 | user | 中（新增实体+Migration） |
| P0 | 2 | parentMessageId 类型不匹配 | chat | 低（改类型） |
| P1 | 3 | Agent 工具/知识库关联塞 JSON | agent | 高（新增关联+Migration） |
| P1 | 4 | AiModel 明文存 API Key | model | 已移至 javis-model，待加密 |
| P1 | 5 | 工作流缺 edge 表 | workflow | 中（新增实体+Migration） |
| P2 | 6 | resourceType 无枚举约束 | user | 低（改为枚举） |
| P2 | 7 | Agent.modelId 用 String 非关联 | agent | 已修复（domain 改用 UUID 引用） |
| P3 | 8 | Conversation 缺最后消息预览 | chat | 低（加冗余字段） |
| P3 | 9 | Conversation.modelId 意图不明确 | chat | 已修复（改 UUID + 加注释） |
| P3 | 10 | Chunk 冗余关联 KnowledgeBase | knowledge | 低（加约束） |
| P3 | 11 | positionX/Y 精度过剩 | workflow | 低（改类型） |
| P3 | 12 | @SQLRestriction 隐藏陷阱 | common | 低（补充方法） |
