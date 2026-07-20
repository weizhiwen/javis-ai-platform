# Javis AI Platform

企业级 AI Agent 平台，基于 Java 25 和 Spring Boot 构建。

## 技术栈

### 后端
- **Java**: 25
- **Spring Boot**: 4.0.7
- **Embabel Agent**: 1.0.0
- **数据库**: PostgreSQL 16 + pgvector
- **缓存**: Redis 7
- **ORM**: Spring Data JPA

### 前端
- **Vue**: 3.5
- **TypeScript**: 5.7
- **Vite**: 6.0
- **UI 框架**: Naive UI
- **状态管理**: Pinia
- **路由**: Vue Router

## 项目结构

```
javis-ai-platform
├── backend/
│   ├── javis-application      # Spring Boot 启动模块
│   ├── javis-domain           # 核心领域模型
│   ├── javis-agent            # AI Agent 核心 (Embabel)
│   ├── javis-knowledge        # 知识库模块
│   ├── javis-workflow         # 工作流引擎
│   ├── javis-tool             # Agent 工具系统
│   ├── javis-model            # 模型抽象层
│   ├── javis-security         # 权限体系
│   └── javis-infrastructure   # 基础设施
├── frontend/                  # Vue 3 前端
├── docker/                    # Docker 配置
├── docs/                      # 文档
└── docker-compose.yml         # Docker Compose 配置
```

## 快速开始

### 前置条件
- JDK 25+
- Maven 3.9+
- Node.js 20+
- Docker & Docker Compose

### 1. 启动基础设施

```bash
docker-compose up -d
```

这将启动:
- PostgreSQL 16 (端口 5432)
- Redis 7 (端口 6379)

### 2. 启动后端

```bash
cd backend
mvn clean install
cd javis-application
mvn spring-boot:run
```

后端服务将在 `http://localhost:8080` 启动。

### 3. 启动前端

```bash
cd frontend
npm install
npm run dev
```

前端服务将在 `http://localhost:3000` 启动。

## 模块说明

### javis-domain
核心领域模型，包含所有业务实体：
- User, Role, Permission, Tenant (权限)
- Agent, AgentVersion, Prompt (智能体)
- Conversation, Message (对话)
- KnowledgeBase, Document, Chunk (知识库)
- ToolDefinition (工具)
- WorkflowDefinition, WorkflowNode (工作流)

### javis-agent
AI Agent 核心模块，基于 Embabel Agent Framework：
- Agent 定义与执行
- Goal/Action/Condition 管理
- Agent 执行上下文

### javis-model
模型抽象层，支持多种 LLM 提供商：
- OpenAI
- DeepSeek
- Qwen
- Claude
- Gemini
- Ollama

### javis-knowledge
知识库模块：
- 文档上传与解析
- 文本切分 (Chunk)
- Embedding 生成
- 向量搜索 (pgvector)

### javis-workflow
工作流引擎：
- DAG 执行引擎
- 节点类型: Start, Agent, LLM, Tool, Condition, End

### javis-tool
Agent 工具系统：
- HTTP Tool
- Database Tool
- Java Method Tool
- MCP Tool

### javis-security
权限体系：
- Spring Security
- JWT 认证
- RBAC 权限模型

### javis-infrastructure
基础设施：
- JPA 配置
- Redis 配置
- 文件存储 (本地/可扩展)

## 开发规范

### Java
- 使用 Java 25 特性 (Record, Pattern Matching)
- 遵循 DDD 原则
- 使用 Lombok 减少样板代码
- 使用 MapStruct 进行对象映射

### 前端
- 使用 Composition API
- 使用 `<script setup>` 语法
- TypeScript 严格模式

### 数据库
- 使用 UUID 作为主键
- 所有实体包含: id, createdAt, updatedAt, deleted
- 软删除使用 `@SQLRestriction("deleted = false")`

## 环境变量

复制 `.env.example` 为 `.env` 并配置：

```bash
cp .env.example .env
```

主要配置项：
- `OPENAI_API_KEY`: OpenAI API 密钥
- `POSTGRES_PASSWORD`: PostgreSQL 密码
- `REDIS_PASSWORD`: Redis 密码

## 文档

详细设计文档请查看 [docs/](./docs/) 目录。

## License

MIT
