# AGENTS.md

## Project Overview

Javis AI Platform — 企业级 AI Agent 平台。Java 25 + Spring Boot 3.5 后端（多模块 Maven），Vue 3 + TypeScript + Naive UI 前端。

## Architecture

### Backend Modules (DDD 分层)

```
javis-domain           Layer 0  核心业务领域，零内部依赖。只含业务概念，不含 AI 技术细节
javis-model            Layer 1  AI 模型接入能力 → domain。屏蔽模型厂商差异（provider/apiKey/baseUrl）
javis-security         Layer 1  权限体系 → domain
javis-infrastructure   Layer 1  基础设施 → domain
javis-tool             Layer 2  工具系统 → domain, model
javis-knowledge        Layer 2  知识库 → domain, model
javis-agent            Layer 3  Agent 核心 → domain, model, tool
javis-workflow         Layer 4  工作流引擎 → domain, agent, tool
javis-application      Layer 5  Spring Boot 启动模块，聚合所有模块
```

依赖方向只能从上到下，禁止反向依赖或循环依赖。

**domain 与 model 的职责边界**:
- `javis-domain`: 定义业务对象（Agent、Conversation、KnowledgeBase），不感知 OpenAI/DeepSeek/API Key
- `javis-model`: 定义 AI 模型接入（ModelConfig、ModelProvider、HTTP 调用），屏蔽厂商差异
- domain 实体通过 UUID 引用模型（如 `AgentVersion.modelId`），不直接依赖 model 模块

### Frontend Structure

```
src/
├── App.vue         根组件
├── main.ts         应用入口
├── assets/         静态资源
├── components/     可复用组件
├── composables/    组合式函数
├── layouts/        布局组件
├── pages/          页面级组件
├── router/         路由配置
├── stores/         Pinia 状态管理
├── types/          TypeScript 类型定义
├── utils/          工具函数
└── views/          视图组件 (按业务域分目录)
```

## Commands

### Infrastructure

```bash
make infra            # 启动 PostgreSQL + Redis (Docker)
make infra-down       # 停止基础设施
make stop             # 停止所有服务
```

### Backend

```bash
cd backend
mvn clean install                          # 编译全部模块
mvn test                                   # 运行全部单元测试
mvn verify                                 # 运行单元测试 + 集成测试 (含 Testcontainers)
mvn spotless:apply                         # 格式化代码
mvn spotless:check                         # 检查代码格式
mvn -pl javis-agent test                   # 运行单个模块测试
mvn -pl javis-agent test -Dtest=AgentTest  # 运行单个测试类
cd javis-application && mvn spring-boot:run # 启动后端 (端口 8080, context-path: /api)
```

### Frontend

```bash
cd frontend
npm install              # 安装依赖
npm run dev              # 开发服务器 (端口 3000, 代理 /api → 8080)
npm run build            # 生产构建 (先 type-check 再 vite build)
npm run type-check       # TypeScript 类型检查 (vue-tsc --noEmit)
npm run lint             # ESLint 检查并自动修复
npm run lint:check       # ESLint 仅检查不修复
npm run test:e2e         # Playwright E2E 测试
npm run test:e2e:ui      # Playwright E2E 测试 (交互模式)
```

### Full Stack

```bash
make dev                 # 启动完整开发环境 (infra + backend + frontend)
make format              # 格式化全部代码 (后端 + 前端)
make test                # 运行后端测试
make test-frontend       # 运行前端类型检查
make build               # 构建后端
make build-frontend      # 构建前端
```

## Coding Conventions

### Java (Backend)

- **Java 25**: 使用 Record、Pattern Matching、Sealed Classes、Text Blocks、Switch Expressions
- **DDD**: 领域逻辑在 `javis-domain`，应用逻辑在 `javis-application`，基础设施在 `javis-infrastructure`
- **Lombok**: 使用 `@Getter`、`@Setter`、`@Builder`、`@NoArgsConstructor`、`@AllArgsConstructor` 等减少样板代码
- **MapStruct**: 对象映射使用 MapStruct，Mapper 接口命名为 `XxxMapper`
- **命名规范**:
  - Entity: `Agent`, `User`, `Conversation`
  - Repository: `AgentRepository` (继承 `BaseRepository<T, ID>`)
  - Service: `AgentService` / `AgentServiceImpl`
  - Controller: `AgentController`
  - DTO: `AgentDTO`, `AgentCreateRequest`, `AgentUpdateRequest`
  - Mapper: `AgentMapper`
- **异常处理**: 业务异常使用自定义 `BusinessException`，通过全局异常处理器统一返回
- **API 路径**: RESTful 风格，复数名词 (`/api/v1/agents`, `/api/v1/agents/{id}`)

### Vue / TypeScript (Frontend)

- **Composition API**: 必须使用 `<script setup lang="ts">` 语法
- **TypeScript**: 严格模式，禁止 `any`，所有 props/emits 必须声明类型
- **组件命名**: PascalCase 文件名 (`AgentCard.vue`)，模板中 PascalCase 引用
- **组合式函数**: `use` 前缀 (`useAgent`, `useChat`)，放在 `composables/`
- **状态管理**: Pinia stores 使用 Setup Store 风格，放在 `stores/`
- **样式**: 使用 `<style scoped>`，避免全局样式污染
- **路径别名**: `@/` 指向 `src/`

### Database

- **主键**: UUID (`GenerationType.UUID`)
- **基础字段**: 所有实体继承 `BaseEntity`，包含 `id`, `createdAt`, `updatedAt`, `deleted`
- **软删除**: `@SQLRestriction("deleted = false")` 自动过滤已删除记录；删除操作调用 `entity.softDelete()`
- **唯一约束**: 使用 Flyway migration 创建 Partial Unique Index（`WHERE deleted = FALSE`），Entity 中不写 `unique = true`
- **Migration**: Flyway 管理，文件位于 `backend/javis-application/src/main/resources/db/migration/`
  - 命名规则: `V{序号}__{描述}.sql` (如 `V1__init_schema.sql`, `V2__add_agent_version.sql`)
  - 每个 migration 必须幂等或提供回滚脚本
  - 修改已有 migration 禁止，只能新增

## Testing

### Backend Testing

测试框架: **JUnit 5** + **AssertJ** + **Mockito** + **Spring Boot Test** + **Testcontainers**

测试分层:

| 类型 | 位置 | 说明 |
|------|------|------|
| 单元测试 | `src/test/java/.../` | 测试业务逻辑，使用 Mockito mock 依赖 |
| 集成测试 | `src/test/java/.../` | 使用 `@SpringBootTest` + Testcontainers 启动真实 PostgreSQL |
| Repository 测试 | `src/test/java/.../repository/` | 使用 `@DataJpaTest` + Testcontainers |

命名规范:
- 测试类: `XxxTest` (单元测试), `XxxIT` (集成测试)
- 测试方法: `should_预期行为_when_条件()` 或 `方法名_场景_预期结果()`

```java
// 单元测试示例
@ExtendWith(MockitoExtension.class)
class AgentServiceTest {
    @Mock AgentRepository agentRepository;
    @InjectMocks AgentServiceImpl agentService;

    @Test
    void should_return_agent_when_exists() { ... }
}

// 集成测试示例
@SpringBootTest
@Testcontainers
class AgentRepositoryIT {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("pgvector/pgvector:pg16");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

运行集成测试: `mvn verify` (绑定到 `integration-test` profile)
运行单元测试: `mvn test`

### Frontend Testing

E2E 测试框架: **Playwright**

测试文件位于 `frontend/e2e/`，按页面组织:

```
e2e/
└── login.spec.ts
```

命名规范: `{页面/功能}.spec.ts`

Playwright 配置要点:
- `baseURL`: `http://localhost:3000`
- 使用 `test.describe` 组织相关测试
- 优先使用 `getByRole`, `getByText` 等语义化选择器
- 测试前确保后端和前端服务已启动

## Code Formatting

### Backend: Spotless

使用 **Spotless** Maven 插件 + **Google Java Format** (AOSP 变体，4 空格缩进)。

配置在 `backend/pom.xml` 中，CI 中通过 `mvn spotless:check` 检查。提交前必须运行 `mvn spotless:apply`。

### Frontend: ESLint

- **ESLint 9** flat config (`eslint.config.js`)
- 规则: `@vue/eslint-config-typescript` (`strictTypeChecked`) + `plugin:vue/flat/recommended`
- 提交前必须通过 `npm run lint:check` 和 `npm run type-check`

## Commit Convention

采用 **Conventional Commits** 规范:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

| Type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复 Bug |
| `docs` | 文档变更 |
| `style` | 代码格式 (不影响逻辑) |
| `refactor` | 重构 (非新功能、非修复) |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `build` | 构建系统或外部依赖变更 |
| `ci` | CI/CD 配置变更 |
| `chore` | 其他不修改源代码的变更 |

### Scope

使用模块名作为 scope: `agent`, `domain`, `model`, `tool`, `knowledge`, `workflow`, `security`, `infrastructure`, `application`, `frontend`, `docker`, `db`

### 示例

```
feat(agent): add agent execution retry with exponential backoff
fix(domain): resolve soft-delete unique constraint conflict on user email
refactor(workflow): extract DAG validation into separate service
test(knowledge): add integration tests for document chunking
chore(docker): upgrade PostgreSQL to 16.4
docs(README): update quick start guide
```

## Key Design Decisions

1. **软删除 + Partial Unique Index**: 所有实体软删除，唯一约束通过 Flyway 创建 `WHERE deleted = FALSE` 的 partial index
2. **Flyway 管理 Schema**: `ddl-auto: validate`，禁止 Hibernate 自动变更 schema
3. **Embabel Agent Framework**: Agent 核心基于 Embabel 1.0.0
4. **pgvector**: 向量搜索使用 PostgreSQL pgvector 扩展
5. **多 LLM 支持**: `javis-model` 模块封装 AI 模型接入能力（ModelConfig/ModelProvider），支持 OpenAI / DeepSeek / Qwen / Claude / Gemini / Ollama；`javis-domain` 通过 UUID 引用模型，不感知技术细节
6. **前端代理**: 开发环境 Vite 将 `/api` 请求代理到后端 `localhost:8080`
