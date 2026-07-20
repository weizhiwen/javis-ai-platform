import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/LoginView.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    component: () => import('@/layouts/AppLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        redirect: '/dashboard'
      },
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/DashboardView.vue')
      },
      {
        path: 'agent',
        name: 'AgentList',
        component: () => import('@/views/agent/AgentListView.vue')
      },
      {
        path: 'agent/:id',
        name: 'AgentEdit',
        component: () => import('@/views/agent/AgentEditView.vue')
      },
      {
        path: 'chat',
        name: 'Chat',
        component: () => import('@/views/chat/ChatView.vue')
      },
      {
        path: 'knowledge',
        name: 'Knowledge',
        component: () => import('@/views/knowledge/KnowledgeView.vue')
      },
      {
        path: 'workflow',
        name: 'Workflow',
        component: () => import('@/views/workflow/WorkflowView.vue')
      },
      {
        path: 'model',
        name: 'Model',
        component: () => import('@/views/model/ModelView.vue')
      },
      {
        path: 'tool',
        name: 'Tool',
        component: () => import('@/views/tool/ToolView.vue')
      },
      {
        path: 'settings',
        name: 'Settings',
        component: () => import('@/views/settings/SettingsView.vue')
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
