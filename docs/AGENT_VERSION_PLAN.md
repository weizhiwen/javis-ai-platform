# Agent 版本管理方案

## 方案：快照子表模式

用 `agent_versions` 子表存储可变快照，`agents` 只存不变信息。

> ⚠️ 数据库可随时清空重建，全部改 V1 即可，不需要 V2 migration。

---

## 一、数据库变更（改 V1）

### 1. 修改 `agents` 表

```sql
-- agents 精简为不变信息字段
ALTER TABLE agents
    DROP COLUMN system_prompt,
    DROP COLUMN model_id,
    DROP COLUMN published,
    DROP COLUMN version;
-- 注意: config_json 已在上一轮从 agents 删除，这里不要再删
```

### 2. 重建 `agent_versions` 表

```sql
-- agent_versions 必须先建（不含 agent_id FK），避免循环
CREATE TABLE agent_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL,                           -- FK 稍后补
    version VARCHAR(50) NOT NULL DEFAULT '0.0.0',     -- DRAFT 用 "0.0.0"
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',      -- DRAFT / PUBLISHED / ARCHIVED
    system_prompt TEXT,
    model_id UUID REFERENCES ai_models(id),           -- 统一用 UUID 引用 AiModel
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 先不建 UNIQUE 索引（等表建完再补）
```

### 3. 修改 `agents` 表加 current_version_id

```sql
ALTER TABLE agents
    ADD COLUMN current_version_id UUID REFERENCES agent_versions(id);
```

### 4. 补 `agent_versions.agent_id` 的外键

```sql
ALTER TABLE agent_versions
    ADD CONSTRAINT fk_agent_versions_agent
    FOREIGN KEY (agent_id) REFERENCES agents(id);
```

### 5. 唯一索引（只约束已发布的版本）

```sql
CREATE UNIQUE INDEX uk_agent_version_published
    ON agent_versions(agent_id, version)
    WHERE deleted = FALSE AND status = 'PUBLISHED';
```

### 6. 普通索引

```sql
CREATE INDEX idx_agent_versions_agent_id ON agent_versions(agent_id);
CREATE INDEX idx_agent_versions_status ON agent_versions(status);
```

### 7. 版本的工具绑定表（替代旧的 `agent_tools`）

```sql
CREATE TABLE agent_version_tools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID NOT NULL REFERENCES agent_versions(id),
    tool_id UUID NOT NULL REFERENCES tool_definitions(id),
    sort_order INTEGER,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_avt_version_id ON agent_version_tools(version_id);
```

### 8. 版本的知识库关联表（替代旧的 `agent_knowledge_bases`）

```sql
CREATE TABLE agent_version_knowledge_bases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID NOT NULL REFERENCES agent_versions(id),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id),
    top_k INTEGER DEFAULT 5,
    similarity_threshold DOUBLE PRECISION DEFAULT 0.7,
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_avkb_version_id ON agent_version_knowledge_bases(version_id);
```

---

## 二、Java Entity 变更

### 1. `Agent.java` — 精简

```java
@Entity
@Table(name = "agents")
public class Agent extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column
    private String description;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id")
    private User creator;

    /** 当前生效的版本（最新发布版本） */
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_version_id")
    private AgentVersion currentVersion;

    /** 所有版本历史 */
    @OneToMany(mappedBy = "agent", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("createdAt DESC")
    private List<AgentVersion> versions = new ArrayList<>();

    // 已删除: systemPrompt, modelId, published, version, tools, knowledgeBases
    // Prompt 模板仍关联 Agent，不做版本化
}
```

### 2. 新建 `AgentVersion.java`

```java
@Getter
@Setter
@Entity
@Table(name = "agent_versions")
public class AgentVersion extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "agent_id", nullable = false, insertable = false, updatable = false)
    private Agent agent;

    @Column(nullable = false)
    private String version;     // 发布版: "1.0.0", DRAFT: "0.0.0"

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VersionStatus status = VersionStatus.DRAFT;

    @Column(name = "system_prompt", columnDefinition = "TEXT")
    private String systemPrompt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "model_id")
    private AiModel model;

    /** 版本绑定的工具 */
    @OneToMany(mappedBy = "version", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AgentVersionTool> tools = new ArrayList<>();

    /** 版本关联的知识库 */
    @OneToMany(mappedBy = "version", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AgentVersionKnowledgeBase> knowledgeBases = new ArrayList<>();

    public enum VersionStatus {
        DRAFT, PUBLISHED, ARCHIVED
    }
}
```

### 3. 新建 `AgentVersionTool.java`

```java
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

    @Column(name = "sort_order")
    private Integer sortOrder;

    @Column(nullable = false)
    private boolean enabled = true;
}
```

### 4. 新建 `AgentVersionKnowledgeBase.java`

```java
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

    @Column(name = "top_k")
    private Integer topK = 5;

    @Column(name = "similarity_threshold")
    private Double similarityThreshold = 0.7;

    @Column(name = "sort_order")
    private Integer sortOrder;
}
```

### 5. 删除

```
删除: AgentTool.java          → 被 AgentVersionTool 替代
删除: AgentKnowledgeBase.java → 被 AgentVersionKnowledgeBase 替代
```

### 6. 不变

```
Prompt.java            → 仍归属 Agent（不版本化，模板可跨版本复用）
```

---

## 三、核心业务逻辑

### 创建 Agent

```java
// 创建 Agent 时自动创建初始 DRAFT 版本
Agent agent = new Agent();
agent.setName("客服助手");
agent = agentRepository.save(agent);

AgentVersion version = new AgentVersion();
version.setAgent(agent);
version.setVersion("0.0.0");   // DRAFT 默认版本
version.setStatus(DRAFT);
versionRepository.save(version);

agent.setCurrentVersion(null); // 刚创建尚未发布，无当前版本
```

### 保存草稿

```java
// 每次保存: 更新已有 DRAFT，或创建新 DRAFT
AgentVersion draft = findDraftByAgentId(agentId);
if (draft == null) {
    draft = new AgentVersion();
    draft.setAgent(agent);
    draft.setVersion("0.0.0");
    draft.setStatus(DRAFT);
}
draft.setSystemPrompt(newPrompt);
draft.setModel(newModel);
draft.setTools(newTools);      // clear + addAll
draft.setKnowledgeBases(newKBs);
versionRepository.save(draft);
```

### 发布

```java
// 将 DRAFT 发布为正式版本
String nextVersion = generateNextVersion(agent.getCurrentVersion());
draft.setVersion(nextVersion);    // "1.0.0" → "1.1.0"
draft.setStatus(PUBLISHED);
versionRepository.save(draft);

agent.setCurrentVersion(draft);   // 更新 agent 的当前版本
agentRepository.save(agent);
```

### 版本号生成

```java
private String generateNextVersion(AgentVersion current) {
    if (current == null) return "1.0.0";
    String[] parts = current.getVersion().split("\\.");
    int minor = Integer.parseInt(parts[1]) + 1;
    return parts[0] + "." + minor + "." + parts[2];
}
```

### 回滚

```java
// 复制历史版本为新的 DRAFT
AgentVersion historical = versionRepository.findById(targetVersionId);
AgentVersion draft = new AgentVersion();
draft.setAgent(historical.getAgent());
draft.setVersion("0.0.0");
draft.setStatus(DRAFT);
draft.setSystemPrompt(historical.getSystemPrompt());
draft.setModel(historical.getModel());
// 复制工具/知识库关联 ...
versionRepository.save(draft);
```

### 查询当前生效配置

```java
Agent agent = agentRepository.findById(id);
// 如果已发布，取 currentVersion；否则取最新 DRAFT
AgentVersion active = agent.getCurrentVersion() != null
    ? agent.getCurrentVersion()
    : agent.getVersions().stream()
        .filter(v -> v.getStatus() == DRAFT)
        .findFirst().orElse(null);

active.getSystemPrompt();   // 当前生效的 prompt
active.getTools();          // 当前绑定的工具
active.getModel();          // 当前使用的模型
```

---

## 四、整理清单

### 新建文件
| 文件 | 说明 |
|------|------|
| `AgentVersion.java` | 版本快照实体 |
| `AgentVersionTool.java` | 版本-工具关联 |
| `AgentVersionKnowledgeBase.java` | 版本-知识库关联 |

### 修改文件
| 文件 | 改动 |
|------|------|
| `Agent.java` | 删 `systemPrompt, modelId, published, version, tools, knowledgeBases`；加 `currentVersion`, `versions` |
| `V1__init_schema.sql` | 按上面 SQL 改 |

### 删除文件
| 文件 | 原因 |
|------|------|
| `AgentTool.java` | 被 `AgentVersionTool` 替代 |
| `AgentKnowledgeBase.java` | 被 `AgentVersionKnowledgeBase` 替代 |

### 不变文件
| 文件 | 原因 |
|------|------|
| `Prompt.java` | 提示词模板库，不随版本变化，仍关联 `Agent` |
