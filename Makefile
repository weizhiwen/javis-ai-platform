.PHONY: help dev infra backend frontend stop clean restart logs

.DEFAULT_GOAL := help

help: ## 显示帮助信息
	@echo "Javis AI Platform - Makefile Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

dev: infra ## 启动完整开发环境 (基础设施 + 后端 + 前端)
	@echo "Starting backend and frontend..."
	@echo "Building backend..."
	@cd backend && mvn clean install -DskipTests -q
	@echo "Starting backend in background..."
	@cd backend/javis-application && mvn spring-boot:run > /tmp/javis-backend.log 2>&1 &
	@echo "Starting frontend..."
	@cd frontend && npm install --silent && npm run dev

infra: ## 启动基础设施 (PostgreSQL + Redis)
	@echo "Starting infrastructure..."
	@docker-compose up -d
	@echo "Infrastructure started. Waiting for services to be ready..."
	@sleep 3
	@docker-compose ps

infra-down: ## 停止基础设施
	docker-compose down -v

backend: ## 启动后端服务
	@echo "Starting backend..."
	cd backend && mvn clean install -DskipTests
	cd backend/javis-application && mvn spring-boot:run

backend-quick: ## 快速启动后端 (跳过编译)
	@echo "Starting backend (quick mode)..."
	cd backend/javis-application && mvn spring-boot:run

frontend: ## 启动前端服务
	@echo "Starting frontend..."
	cd frontend && npm install && npm run dev

frontend-quick: ## 快速启动前端 (跳过安装)
	@echo "Starting frontend (quick mode)..."
	cd frontend && npm run dev

stop: ## 停止所有服务
	@echo "Stopping all services..."
	@pkill -f "spring-boot:run" || true
	@pkill -f "vite" || true
	docker-compose stop
	@echo "All services stopped"

clean: ## 清理构建产物和容器
	@echo "Cleaning up..."
	docker-compose down -v
	cd backend && mvn clean
	rm -rf frontend/node_modules frontend/dist
	@echo "Cleanup complete"

restart: stop dev ## 重启所有服务

logs: ## 查看基础设施日志
	docker-compose logs -f

logs-backend: ## 查看后端日志
	tail -f backend/javis-application/logs/application.log

logs-postgres: ## 查看 PostgreSQL 日志
	docker-compose logs -f postgres

logs-redis: ## 查看 Redis 日志
	docker-compose logs -f redis

build: ## 构建后端
	cd backend && mvn clean install

build-frontend: ## 构建前端
	cd frontend && npm run build

test: ## 运行后端测试
	cd backend && mvn test

test-frontend: ## 运行前端类型检查
	cd frontend && npm run type-check

test-e2e: ## 运行前端 E2E 测试
	cd frontend && npm run test:e2e

format: ## 格式化代码
	cd backend && mvn spotless:apply
	cd frontend && npm run lint

db-shell: ## 进入 PostgreSQL shell
	docker-compose exec postgres psql -U javis -d javis

redis-shell: ## 进入 Redis shell
	docker-compose exec redis redis-cli

status: ## 查看所有服务状态
	@echo "=== Docker Containers ==="
	@docker-compose ps
	@echo ""
	@echo "=== Backend Process ==="
	@ps aux | grep "spring-boot:run" | grep -v grep || echo "Backend not running"
	@echo ""
	@echo "=== Frontend Process ==="
	@ps aux | grep "vite" | grep -v grep || echo "Frontend not running"
