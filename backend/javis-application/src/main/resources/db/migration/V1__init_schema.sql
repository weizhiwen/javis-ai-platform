-- ============================================================================
-- V1__init_schema.sql
-- 初始化数据库 schema，使用 Partial Unique Index 支持软删除
-- ============================================================================

-- 启用 pgvector 扩展（用于知识库向量搜索）
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- 1. 权限相关表
-- ============================================================================

-- 租户表
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 租户名称部分唯一索引（只约束未删除的记录）
CREATE UNIQUE INDEX uk_tenants_name_active ON tenants(name) WHERE deleted = FALSE;

-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    avatar VARCHAR(1000),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    tenant_id UUID REFERENCES tenants(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 用户名部分唯一索引
CREATE UNIQUE INDEX uk_users_username_active ON users(username) WHERE deleted = FALSE;
-- 邮箱部分唯一索引
CREATE UNIQUE INDEX uk_users_email_active ON users(email) WHERE deleted = FALSE;
-- 租户索引
CREATE INDEX idx_users_tenant_id ON users(tenant_id);

-- 角色表
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 角色代码部分唯一索引
CREATE UNIQUE INDEX uk_roles_code_active ON roles(code) WHERE deleted = FALSE;

-- 权限表
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    resource_type VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 权限代码部分唯一索引
CREATE UNIQUE INDEX uk_permissions_code_active ON permissions(code) WHERE deleted = FALSE;

-- ============================================================================
-- 2. AI 模型相关表
-- ============================================================================

CREATE TABLE ai_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    model_id VARCHAR(255) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    api_key VARCHAR(1000),
    base_url VARCHAR(1000),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    description VARCHAR(1000),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_ai_models_provider ON ai_models(provider);

-- ============================================================================
-- 3. Agent 相关表
-- ============================================================================

CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    system_prompt TEXT,
    avatar_url VARCHAR(1000),
    model_id VARCHAR(255),
    creator_id UUID REFERENCES users(id),
    published BOOLEAN NOT NULL DEFAULT FALSE,
    version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_agents_creator_id ON agents(creator_id);

CREATE TABLE agent_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents(id),
    version VARCHAR(50) NOT NULL,
    system_prompt TEXT,
    model_id VARCHAR(255),
    config_json TEXT,
    active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_agent_versions_agent_id ON agent_versions(agent_id);

CREATE TABLE prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    template_content TEXT NOT NULL,
    description VARCHAR(1000),
    agent_id UUID REFERENCES agents(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_prompts_agent_id ON prompts(agent_id);

-- ============================================================================
-- 4. 对话相关表
-- ============================================================================

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    agent_id UUID NOT NULL REFERENCES agents(id),
    user_id UUID NOT NULL REFERENCES users(id),
    model_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_conversations_agent_id ON conversations(agent_id);
CREATE INDEX idx_conversations_user_id ON conversations(user_id);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    token_count INTEGER,
    parent_message_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_role ON messages(role);

-- ============================================================================
-- 5. 知识库相关表
-- ============================================================================

CREATE TABLE knowledge_bases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    creator_id UUID REFERENCES users(id),
    embedding_model_id VARCHAR(255),
    chunk_size INTEGER DEFAULT 500,
    chunk_overlap INTEGER DEFAULT 50,
    document_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_knowledge_bases_creator_id ON knowledge_bases(creator_id);

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id),
    file_path VARCHAR(1000),
    file_size BIGINT,
    mime_type VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    chunk_count INTEGER DEFAULT 0,
    metadata TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_documents_knowledge_base_id ON documents(knowledge_base_id);
CREATE INDEX idx_documents_status ON documents(status);

CREATE TABLE chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    knowledge_base_id UUID NOT NULL REFERENCES knowledge_bases(id),
    content TEXT NOT NULL,
    chunk_index INTEGER,
    token_count INTEGER,
    embedding_vector vector(1536),
    metadata TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_chunks_document_id ON chunks(document_id);
CREATE INDEX idx_chunks_knowledge_base_id ON chunks(knowledge_base_id);
-- 向量索引（使用 ivfflat，需要先有数据才能创建，这里先创建普通索引）
CREATE INDEX idx_chunks_embedding_vector ON chunks USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100);

-- ============================================================================
-- 6. 工具相关表
-- ============================================================================

CREATE TABLE tool_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    tool_type VARCHAR(50) NOT NULL,
    config_json TEXT,
    schema_json TEXT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_tool_definitions_tool_type ON tool_definitions(tool_type);

-- ============================================================================
-- 7. 工作流相关表
-- ============================================================================

CREATE TABLE workflow_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    dag_json TEXT,
    creator_id UUID REFERENCES users(id),
    published BOOLEAN NOT NULL DEFAULT FALSE,
    version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_workflow_definitions_creator_id ON workflow_definitions(creator_id);

CREATE TABLE workflow_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflow_definitions(id),
    node_key VARCHAR(255) NOT NULL,
    node_type VARCHAR(50) NOT NULL,
    config_json TEXT,
    position_x DOUBLE PRECISION,
    position_y DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_workflow_nodes_workflow_id ON workflow_nodes(workflow_id);
CREATE INDEX idx_workflow_nodes_node_type ON workflow_nodes(node_type);

-- ============================================================================
-- 8. 插入初始数据
-- ============================================================================

-- 插入默认租户
INSERT INTO tenants (id, name, description, active) VALUES
('00000000-0000-0000-0000-000000000001', 'Default Tenant', 'Default tenant for single-tenant mode', TRUE);

-- 插入默认管理员用户（密码: admin123，需要 BCrypt 加密）
INSERT INTO users (id, username, email, password, display_name, enabled, tenant_id) VALUES
('00000000-0000-0000-0000-000000000002', 'admin', 'admin@javis.ai', '$2a$10$N.zmdr9kLUuOCNHbq9bKYO5bZqKbqKqKqKqKqKqKqKq', 'Administrator', TRUE, '00000000-0000-0000-0000-000000000001');

-- 插入默认角色
INSERT INTO roles (id, code, name, description) VALUES
('00000000-0000-0000-0000-000000000003', 'ADMIN', 'Administrator', 'System administrator with full access'),
('00000000-0000-0000-0000-000000000004', 'USER', 'User', 'Regular user with basic access');

-- 插入默认权限
INSERT INTO permissions (id, code, name, description, resource_type) VALUES
('00000000-0000-0000-0000-000000000005', 'agent:create', 'Create Agent', 'Permission to create agents', 'agent'),
('00000000-0000-0000-0000-000000000006', 'agent:read', 'Read Agent', 'Permission to read agents', 'agent'),
('00000000-0000-0000-0000-000000000007', 'agent:update', 'Update Agent', 'Permission to update agents', 'agent'),
('00000000-0000-0000-0000-000000000008', 'agent:delete', 'Delete Agent', 'Permission to delete agents', 'agent');
