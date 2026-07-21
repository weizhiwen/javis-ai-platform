-- ============================================================================
-- V1__init_schema.sql
-- 初始化数据库 schema，使用 Partial Unique Index 支持软删除
-- ============================================================================

-- 启用 pgvector 扩展（用于知识库向量搜索）
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- 1. 权限相关表
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    avatar VARCHAR(1000),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX uk_users_username_active ON users(username) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_users_email_active ON users(email) WHERE deleted = FALSE;

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX uk_roles_code_active ON roles(code) WHERE deleted = FALSE;

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    resource_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX uk_permissions_code_active ON permissions(code) WHERE deleted = FALSE;

CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id),
    role_id UUID NOT NULL REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id),
    permission_id UUID NOT NULL REFERENCES permissions(id),
    PRIMARY KEY (role_id, permission_id)
);

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
-- 3. 工具相关表（先于 Agent 创建，因为 Agent 关联工具）
-- ============================================================================

CREATE TABLE tool_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    tool_type VARCHAR(50) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_tool_definitions_tool_type ON tool_definitions(tool_type);

CREATE TABLE tool_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tool_id UUID NOT NULL REFERENCES tool_definitions(id),
    config_key VARCHAR(255) NOT NULL,
    config_value TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_tool_configs_tool_id ON tool_configs(tool_id);

CREATE TABLE tool_parameters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tool_id UUID NOT NULL REFERENCES tool_definitions(id),
    name VARCHAR(255) NOT NULL,
    param_type VARCHAR(50) NOT NULL,
    description VARCHAR(1000),
    required BOOLEAN NOT NULL DEFAULT FALSE,
    default_value VARCHAR(1000),
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_tool_parameters_tool_id ON tool_parameters(tool_id);

-- ============================================================================
-- 4. 知识库相关表（先于 Agent 创建，因为 Agent 关联知识库）
-- ============================================================================

CREATE TABLE knowledge_bases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    creator_id UUID REFERENCES users(id),
    embedding_model_id UUID REFERENCES ai_models(id),
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
    metadata JSONB,
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
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_chunks_document_id ON chunks(document_id);
CREATE INDEX idx_chunks_knowledge_base_id ON chunks(knowledge_base_id);
CREATE INDEX idx_chunks_embedding_vector ON chunks USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100);

-- ============================================================================
-- 5. Agent 相关表
-- ============================================================================

-- agents 只存不变信息，可变配置在 agent_versions 中快照
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    avatar_url VARCHAR(1000),
    creator_id UUID REFERENCES users(id),
    current_version_id UUID,                              -- FK 稍后补
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_agents_creator_id ON agents(creator_id);

-- agent_versions 先建（不带 FK），避免与 agents 循环
CREATE TABLE agent_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL,                               -- FK 稍后补
    version VARCHAR(50) NOT NULL DEFAULT '0.0.0',
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    system_prompt TEXT,
    model_id UUID REFERENCES ai_models(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_agent_versions_agent_id ON agent_versions(agent_id);
CREATE INDEX idx_agent_versions_status ON agent_versions(status);

-- 只约束已发布版本的版本号唯一
CREATE UNIQUE INDEX uk_agent_version_published
    ON agent_versions(agent_id, version)
    WHERE deleted = FALSE AND status = 'PUBLISHED';

-- 补 agents.current_version_id 的外键
ALTER TABLE agents
    ADD CONSTRAINT fk_agents_current_version
    FOREIGN KEY (current_version_id) REFERENCES agent_versions(id);

-- current_version_id 唯一约束
CREATE UNIQUE INDEX uk_agents_current_version_id ON agents(current_version_id);

-- 补 agent_versions.agent_id 的外键
ALTER TABLE agent_versions
    ADD CONSTRAINT fk_agent_versions_agent
    FOREIGN KEY (agent_id) REFERENCES agents(id);

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

CREATE INDEX idx_agent_version_tools_version_id ON agent_version_tools(version_id);
CREATE INDEX idx_agent_version_tools_tool_id ON agent_version_tools(tool_id);

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

CREATE INDEX idx_agent_version_kbs_version_id ON agent_version_knowledge_bases(version_id);
CREATE INDEX idx_agent_version_kbs_kb_id ON agent_version_knowledge_bases(knowledge_base_id);

-- ============================================================================
-- 6. 对话相关表
-- ============================================================================

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    agent_id UUID NOT NULL REFERENCES agents(id),
    user_id UUID NOT NULL REFERENCES users(id),
    model_id UUID REFERENCES ai_models(id),
    last_message_preview VARCHAR(200),
    last_message_at TIMESTAMP WITH TIME ZONE,
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
    parent_message_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_role ON messages(role);

-- ============================================================================
-- 7. 工作流相关表
-- ============================================================================

CREATE TABLE workflow_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
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
    config_json JSONB,
    position_x INTEGER,
    position_y INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_workflow_nodes_workflow_id ON workflow_nodes(workflow_id);
CREATE INDEX idx_workflow_nodes_node_type ON workflow_nodes(node_type);

CREATE TABLE workflow_edges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflow_definitions(id),
    source_node_key VARCHAR(255) NOT NULL,
    target_node_key VARCHAR(255) NOT NULL,
    condition_expression VARCHAR(1000),
    label VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_workflow_edges_workflow_id ON workflow_edges(workflow_id);

-- ============================================================================
-- 8. 插入初始数据
-- ============================================================================

INSERT INTO users (id, username, email, password, display_name, enabled) VALUES
('00000000-0000-0000-0000-000000000002', 'admin', 'admin@javis.ai', '$2a$10$N.zmdr9kLUuOCNHbq9bKYO5bZqKbqKqKqKqKqKqKqKq', 'Administrator', TRUE);

INSERT INTO roles (id, code, name, description) VALUES
('00000000-0000-0000-0000-000000000003', 'ADMIN', 'Administrator', 'System administrator with full access'),
('00000000-0000-0000-0000-000000000004', 'USER', 'User', 'Regular user with basic access');

INSERT INTO permissions (id, code, name, description, resource_type) VALUES
('00000000-0000-0000-0000-000000000005', 'agent:create', 'Create Agent', 'Permission to create agents', 'AGENT'),
('00000000-0000-0000-0000-000000000006', 'agent:read', 'Read Agent', 'Permission to read agents', 'AGENT'),
('00000000-0000-0000-0000-000000000007', 'agent:update', 'Update Agent', 'Permission to update agents', 'AGENT'),
('00000000-0000-0000-0000-000000000008', 'agent:delete', 'Delete Agent', 'Permission to delete agents', 'AGENT');

INSERT INTO user_roles (user_id, role_id) VALUES
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003');

INSERT INTO role_permissions (role_id, permission_id) VALUES
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000005'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000006'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000007'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000008');
