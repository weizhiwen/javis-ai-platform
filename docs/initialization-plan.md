# Javis AI Platform 初始化计划

**话题时间**: 2026-07-20 22:00:55 CST

---

## 项目概述

**项目名称**: Javis AI Platform  
**定位**: 基于 Java 25 和 Spring Boot 构建的企业级 AI Agent Platform  
**核心目标**: 打造类似 Dify / Coze 的 AI Agent 平台，采用纯 Java 技术体系

---

## 技术栈确认

| 技术 | 版本 | 说明 |
|------|------|------|
| Java | 25 | 用户指定 |
| Spring Boot | 4.0.7 | 当前最新稳定版 (2026-06-10) |
| Embabel Agent | 1.0.0 | GA 版 (2026-07-20, 今日发布) |
| PostgreSQL | 16 | + pgvector 扩展 |
| Redis | 7 | 缓存/会话 |
| 文件存储 | 本地 | 可插拔扩展: 阿里云 OSS / 腾讯云 COS / 七牛云 |
| Vue | 3 | + TypeScript |
| Vite | 6 | 构建工具 |
| Naive UI | latest | 组件库 |

---

## 架构设计

### 仓库结构 (Monorepo)

```
javis-ai-platform
├── backend
│   ├── javis-application      # Spring Boot 启动模块
│   ├── javis-domain           # 核心领域模型
│   ├── javis-agent            # AI Agent 核心 (Embabel)
│   ├── javis-knowledge        # 知识库模块
│   ├── javis-workflow         # 工作流引擎
│   ├── javis-tool             # Agent 工具系统
│   ├── javis-model            # 模型抽象层
│   ├── javis-security         # 权限体系
│   └── javis-infrastructure   # 基础设施
├── frontend                   # Vue 3 + TypeScript
├── docker                     # Docker 配置
├── docs                       # 文档
├── docker-compose.yml
└── README.md
```

### 后端架构

**架构风格**: DDD + Modular Monolith

**分层结构**:
- `controller` - REST API 层
- `application` - 应用服务层
- `domain` - 领域层
- `infrastructure` - 基础设施层

**禁止事项**:
- Controller 写业务逻辑
- Service 巨型类
- 模块相互强依赖

### 模块依赖关系

```
javis-application (Spring Boot 启动)
├── javis-agent (Embabel 集成)
│   ├── javis-domain
│   ├── javis-model
│   └── javis-tool
├── javis-knowledge
│   ├── javis-domain
│   └── javis-model
├── javis-workflow
│   ├── javis-domain
│   ├── javis-agent
│   └── javis-tool
├── javis-security
│   └── javis-domain
├── javis-infrastructure
│   └── javis-domain
└── javis-model
    └── javis-domain
```

---

## 数据库设计

**数据库**: PostgreSQL 16  
**ORM**: Spring Data JPA  
**主键策略**: UUID

### 实体分类

**Auth (权限)**:
- User
- Role
- Permission
- Tenant

**AI (智能体)**:
- AiModel
- Agent
- AgentVersion
- Prompt

**Chat (对话)**:
- Conversation
- Message

**Knowledge (知识库)**:
- KnowledgeBase
- Document
- Chunk

**Tool (工具)**:
- ToolDefinition

**Workflow (工作流)**:
- WorkflowDefinition
- WorkflowNode

### 公共字段

所有实体包含:
- `id` (UUID, 主键)
- `createdAt` (创建时间)
- `updatedAt` (更新时间)
- `deleted` (软删除标记)

### 软删除方案

**方案**: Hibernate 6 `@SQLRestriction` + 逻辑删除标记

**实现**:
```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {
    @Id
    private UUID id;
    
    @Column(nullable = false)
    private boolean deleted = false;
    
    @Column(nullable = false, updatable = false)
    @CreatedDate
    private Instant createdAt;
    
    @Column(nullable = false)
    @LastModifiedDate
    private Instant updatedAt;
}

@Entity
@Table(name = "users")
@SQLRestriction("deleted = false")
public class User extends BaseEntity {
    // ...
}
```

**优势**:
- 透明过滤: `@SQLRestriction` 自动注入到所有 SELECT/UPDATE/DELETE
- 唯一约束兼容: 使用 partial unique index
- 级联安全: 关联查询同样自动过滤
- 可恢复: 支持 `UPDATE SET deleted = false`

**注意事项**:
- 原生 SQL 不受 `@SQLRestriction` 影响，需手动加 `WHERE deleted = false`
- 唯一约束需在 PostgreSQL 中用 partial index 实现
- `@SQLRestriction` 是 Hibernate 6.3+ 注解，Spring Boot 4.0.7 自带 Hibernate 7.x，完全支持

---

## 前端设计

### 技术栈

- Vue 3 + TypeScript
- Vite 6
- Naive UI
- vue-router
- pinia
- axios

### 页面路由

```
/login              # 登录
/dashboard          # 仪表盘

/agent              # Agent 列表
/agent/:id          # Agent 编辑

/chat               # AI 聊天

/knowledge          # 知识库
/knowledge/:id      # 知识库详情

/workflow           # 工作流设计
/workflow/:id       # 工作流编辑

/model              # 模型管理

/tool               # 工具管理

/settings           # 系统设置
```

### UI 设计方向

**参考**: Dify / Coze / Open WebUI

**要求**:
- 左侧菜单
- 顶部 Header
- 暗色主题支持
- 响应式布局

---

## Docker 环境

**服务**:
- PostgreSQL 16 + pgvector
- Redis 7

**不包含**:
- ~~MinIO~~ (文件存储使用本地，后续可扩展 OSS/COS/Qiniu)

---

## 开发规范

### Java

- Java 25
- Record 优先
- Pattern Matching
- Virtual Thread 可选

**代码风格**:
- Clean Architecture
- DDD
- SOLID

### 前端

- Composition API
- `<script setup>`

---

## 执行计划 (11 步)

| # | 步骤 | 内容 |
|---|------|------|
| 1 | Monorepo 目录 | 创建所有目录骨架：`backend/`, `frontend/`, `docker/`, `docs/` |
| 2 | Maven Parent POM | `backend/pom.xml` - 聚合 POM，统一版本管理 |
| 3 | 9 个模块 POM | 每个子模块 `pom.xml`，正确声明依赖关系 |
| 4 | Spring Boot 初始化 | `JavisApplication.java` + `application.yml` |
| 5 | JPA 基础配置 | `BaseEntity`, `JpaConfig`, `AuditingConfig` |
| 6 | Entity 设计 | 所有领域实体 (User, Agent, Conversation 等) |
| 7 | Embabel Agent 集成 | Agent 配置 + 示例 Agent 骨架 |
| 8 | Frontend 初始化 | Vue3 + TS + Vite + Naive UI |
| 9 | Naive UI 布局 | 主题、路由、Layout 组件 |
| 10 | Docker Compose | PostgreSQL + Redis |
| 11 | README | 项目说明文档 |

---

## 关键设计决策

### 1. Entity 策略

JPA Entity 使用传统 class (非 record)，因为 JPA 需要可变实体 + 懒加载。DTO 层使用 record。

### 2. Embabel 集成

`javis-agent` 模块封装 Embabel 的 `AgentPlatform`，对外提供统一的 Agent 执行接口。

### 3. Model 抽象

`javis-model` 定义 `ModelProvider`/`ChatClient`/`EmbeddingProvider` 接口，底层通过 Embabel 的 LLM 适配实现。

### 4. 文件存储

`StorageService` 接口 + `LocalStorageService` 默认实现，策略模式支持未来扩展 OSS/COS/Qiniu。

### 5. 软删除

使用 `@SQLRestriction("deleted = false")` 实现透明过滤，配合 partial unique index 处理唯一约束。

---

## Embabel 1.0.0 新增模块

- `embabel-agent-starter-webmvc` - Web MVC 集成
- `embabel-agent-starter-a2a` - Agent-to-Agent 协议
- `embabel-agent-starter-mcpserver` - MCP Server 支持
- `embabel-agent-starter-deepseek` / `embabel-agent-starter-ollama` / `embabel-agent-starter-gemini` 等更多模型
- `embabel-agent-rag-*` - RAG 管道支持
- `embabel-agent-byok` - 自带密钥

---

## 复盘要点

### 技术选型理由

1. **Java 25**: 体验最新特性 (Record Patterns, Pattern Matching 等)
2. **Spring Boot 4.0.7**: 当前最新稳定版，性能提升显著
3. **Embabel 1.0.0**: 今日刚发布 GA 版，功能最全，但需注意与 Spring Boot 4.x 兼容性
4. **不使用 Spring AI**: AI Agent 能力全部基于 Embabel 实现
5. **不使用 MinIO**: 文件存储采用本地 + 可插拔策略，降低初期复杂度

### 风险点

1. **Embabel 1.0.0 + Spring Boot 4.0.7 兼容性**: Embabel 1.0.0 今日发布，模板尚未更新，可能存在兼容性问题
2. **Java 25**: 处于 Early Access 阶段，部分库可能未完全适配
3. **Embabel 学习曲线**: 框架相对较新，需要团队学习成本

### 后续优化方向

1. 文件存储扩展: 阿里云 OSS / 腾讯云 COS / 七牛云
2. 向量数据库: pgvector 或 Milvus
3. 工作流引擎: DAG 执行引擎
4. Agent 协作: A2A 协议支持
5. MCP Server: 工具标准化接入

---

**文档创建时间**: 2026-07-20 22:00:55 CST  
**最后更新**: 2026-07-20 22:00:55 CST
