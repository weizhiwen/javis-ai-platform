# 软删除设计审查报告

**审查时间**: 2026-07-20  
**审查人**: PostgreSQL + Hibernate 6 专家  
**项目**: Javis AI Platform

---

## 一、当前设计问题

### 1.1 问题概述

当前使用 `@Column(unique = true)` 创建标准唯一索引，与软删除机制存在**严重冲突**。

### 1.2 受影响的实体和字段

| 实体 | 字段 | 问题 |
|------|------|------|
| `User` | `username` | 删除用户后无法用相同用户名重新注册 |
| `User` | `email` | 删除用户后无法用相同邮箱重新注册 |
| `Tenant` | `name` | 删除租户后无法用相同名称重建 |
| `Role` | `code` | 删除角色后无法用相同 code 重建 |
| `Permission` | `code` | 删除权限后无法用相同 code 重建 |

### 1.3 业务场景失败示例

```
场景：用户注销后重新注册

1. 用户 A (email: test@example.com) 被软删除
2. 数据库中：users 表存在 deleted=true, email=test@example.com 的记录
3. 新用户尝试用 test@example.com 注册
4. ❌ 失败：违反唯一约束 uk_users_email
```

### 1.4 技术层面问题

- **Hibernate `ddl-auto: update`**：会创建标准唯一索引，而非 partial index
- **PostgreSQL 标准唯一索引**：约束所有记录，包括已删除的
- **业务逻辑矛盾**：软删除保留历史数据，但唯一约束阻止数据重用

---

## 二、改造方案

### 2.1 核心思路

使用 **PostgreSQL Partial Unique Index**，只约束 `deleted = false` 的记录：

```sql
CREATE UNIQUE INDEX uk_users_email_active ON users(email) WHERE deleted = FALSE;
```

### 2.2 改造内容

#### 2.2.1 引入 Flyway

**原因**：
- 需要精确控制数据库 schema 变更
- 支持 partial unique index（JPA 不直接支持）
- 生产环境需要版本化的数据库迁移

**改动**：
- 添加 `flyway-core` 和 `flyway-database-postgresql` 依赖
- 修改 `application-dev.yml`：`ddl-auto: validate`，启用 Flyway
- 创建 `db/migration/V1__init_schema.sql`

#### 2.2.2 修改 Entity

移除所有 `unique = true`，唯一约束由 Flyway migration 管理：

```java
// 修改前
@Column(nullable = false, unique = true)
private String email;

// 修改后
@Column(nullable = false)
private String email;
```

#### 2.2.3 创建 Partial Unique Index

```sql
-- 用户表
CREATE UNIQUE INDEX uk_users_username_active ON users(username) WHERE deleted = FALSE;
CREATE UNIQUE INDEX uk_users_email_active ON users(email) WHERE deleted = FALSE;

-- 租户表
CREATE UNIQUE INDEX uk_tenants_name_active ON tenants(name) WHERE deleted = FALSE;

-- 角色表
CREATE UNIQUE INDEX uk_roles_code_active ON roles(code) WHERE deleted = FALSE;

-- 权限表
CREATE UNIQUE INDEX uk_permissions_code_active ON permissions(code) WHERE deleted = FALSE;
```

### 2.3 方案优势

| 特性 | 说明 |
|------|------|
| **软删除兼容** | 删除后的记录不参与唯一约束检查 |
| **数据重用** | 可以用相同值重新创建记录 |
| **高并发安全** | PostgreSQL 保证索引层面的原子性 |
| **查询性能** | Partial index 更小，查询更快 |
| **数据完整性** | 活跃记录的唯一性由数据库保证 |

---

## 三、历史数据处理

### 3.1 当前状态

- 项目处于初始化阶段
- 数据库尚未投入生产使用
- **无历史数据需要迁移**

### 3.2 未来数据处理策略

如果未来需要处理历史数据，执行以下 SQL：

```sql
-- 1. 检查是否存在重复数据（未删除的记录）
SELECT email, COUNT(*) 
FROM users 
WHERE deleted = FALSE 
GROUP BY email 
HAVING COUNT(*) > 1;

-- 2. 如果存在重复，需要先清理（保留最新的一条）
DELETE FROM users a
USING users b
WHERE a.id < b.id
  AND a.email = b.email
  AND a.deleted = FALSE
  AND b.deleted = FALSE;

-- 3. 删除旧的标准唯一索引（如果存在）
DROP INDEX IF EXISTS uk_users_email;

-- 4. 创建 partial unique index
CREATE UNIQUE INDEX uk_users_email_active ON users(email) WHERE deleted = FALSE;
```

### 3.3 数据归档建议

对于长期运行的系统，建议定期清理已删除的历史数据：

```sql
-- 清理 90 天前软删除的数据
DELETE FROM users 
WHERE deleted = TRUE 
  AND updated_at < NOW() - INTERVAL '90 days';
```

---

## 四、上线迁移步骤

### 4.1 开发环境（当前）

```bash
# 1. 停止应用
make stop

# 2. 清理数据库（开发环境）
docker-compose down -v
docker-compose up -d

# 3. 启动应用（Flyway 会自动执行 migration）
make backend

# 4. 验证
# - 检查 flyway_schema_history 表
# - 测试软删除和重新创建场景
```

### 4.2 生产环境（未来）

```bash
# 1. 备份数据库
pg_dump -U javis -d javis > backup_$(date +%Y%m%d).sql

# 2. 停止应用
systemctl stop javis

# 3. 执行 Flyway migration
flyway -url=jdbc:postgresql://localhost:5432/javis \
       -user=javis \
       -password=xxx \
       migrate

# 4. 验证 migration
flyway -url=jdbc:postgresql://localhost:5432/javis \
       -user=javis \
       -password=xxx \
       info

# 5. 启动应用
systemctl start javis

# 6. 验证功能
# - 测试软删除
# - 测试重新创建
# - 检查唯一约束
```

### 4.3 回滚方案

```bash
# Flyway 不支持自动回滚，需要手动准备回滚 SQL
# 建议：每次 migration 都准备对应的 rollback SQL

# 回滚 V1__init_schema.sql
DROP TABLE IF EXISTS workflow_nodes;
DROP TABLE IF EXISTS workflow_definitions;
DROP TABLE IF EXISTS tool_definitions;
DROP TABLE IF EXISTS chunks;
DROP TABLE IF EXISTS documents;
DROP TABLE IF EXISTS knowledge_bases;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS prompts;
DROP TABLE IF EXISTS agent_versions;
DROP TABLE IF EXISTS agents;
DROP TABLE IF EXISTS ai_models;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS tenants;
DROP EXTENSION IF EXISTS vector;
```

---

## 五、风险点

### 5.1 高风险

| 风险 | 说明 | 缓解措施 |
|------|------|---------|
| **Flyway migration 失败** | 生产环境 migration 失败可能导致数据库锁死 | 1. 先在测试环境验证<br>2. 低峰期执行<br>3. 准备回滚方案 |
| **Partial index 不生效** | 查询未使用 `WHERE deleted = false` 导致全表扫描 | 1. `@SQLRestriction` 已自动注入<br>2. 监控慢查询日志 |

### 5.2 中风险

| 风险 | 说明 | 缓解措施 |
|------|------|---------|
| **并发插入冲突** | 两个请求同时插入相同唯一值 | PostgreSQL 保证索引层面原子性，第二个请求会失败 |
| **历史数据冲突** | 生产环境已有重复数据 | 1. migration 前检查<br>2. 准备数据清理脚本 |

### 5.3 低风险

| 风险 | 说明 | 缓解措施 |
|------|------|---------|
| **Hibernate 自动创建索引** | `ddl-auto: update` 可能创建重复索引 | 已改为 `validate`，禁止自动变更 |
| **原生 SQL 绕过软删除** | 使用原生 SQL 未加 `WHERE deleted = false` | 1. 代码审查<br>2. 使用 `@SQLRestriction` |

---

## 六、验证测试

### 6.1 测试用例

```java
@Test
void testSoftDeleteAndRecreate() {
    // 1. 创建用户
    User user1 = new User();
    user1.setEmail("test@example.com");
    user1.setUsername("testuser");
    userRepository.save(user1);
    
    // 2. 软删除
    userRepository.softDeleteById(user1.getId());
    
    // 3. 用相同邮箱重新创建
    User user2 = new User();
    user2.setEmail("test@example.com");
    user2.setUsername("testuser");
    userRepository.save(user2); // ✅ 应该成功
    
    // 4. 验证
    assertThat(userRepository.findAll()).hasSize(1);
    assertThat(userRepository.findByIdNotDeleted(user2.getId())).isPresent();
}

@Test
void testUniqueConstraintOnActiveRecords() {
    // 1. 创建用户
    User user1 = new User();
    user1.setEmail("test@example.com");
    userRepository.save(user1);
    
    // 2. 尝试创建相同邮箱的用户
    User user2 = new User();
    user2.setEmail("test@example.com");
    
    // 3. 应该抛出异常
    assertThatThrownBy(() -> userRepository.save(user2))
        .isInstanceOf(DataIntegrityViolationException.class);
}
```

### 6.2 SQL 验证

```sql
-- 验证 partial unique index 存在
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'users' 
  AND indexdef LIKE '%WHERE%';

-- 测试软删除后重新创建
BEGIN;
INSERT INTO users (username, email, password) VALUES ('test', 'test@example.com', 'xxx');
UPDATE users SET deleted = TRUE WHERE email = 'test@example.com';
INSERT INTO users (username, email, password) VALUES ('test', 'test@example.com', 'xxx');
-- 应该成功
COMMIT;
```

---

## 七、总结

### 7.1 改造收益

1. **业务正确性**：软删除后可以重新创建相同唯一值的记录
2. **数据完整性**：数据库层面保证活跃记录的唯一性
3. **高并发安全**：PostgreSQL 索引层面保证原子性
4. **性能优化**：Partial index 更小，查询更快

### 7.2 注意事项

1. **生产环境慎用**：Flyway migration 需要充分测试
2. **监控慢查询**：确保 `@SQLRestriction` 生效
3. **定期归档**：清理长期软删除的历史数据
4. **代码审查**：避免原生 SQL 绕过软删除

### 7.3 后续优化

1. **添加数据库触发器**：自动更新 `updated_at`
2. **添加审计日志**：记录所有软删除操作
3. **优化向量索引**：根据数据量调整 ivfflat 参数
4. **分区表**：对大表（如 messages）考虑按时间分区

---

**审查结论**：当前软删除设计存在严重缺陷，已完成改造。改造后使用 PostgreSQL Partial Unique Index，既保证了软删除的数据保留，又支持了业务唯一值的重用，满足高并发安全要求。
