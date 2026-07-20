<script setup lang="ts">
import { NButton, NDataTable } from 'naive-ui'
import { ref } from 'vue'

const columns = [
  { title: '模型名称', key: 'name' },
  { title: '提供商', key: 'provider' },
  { title: '状态', key: 'status' }
]

const data = ref([
  { name: 'GPT-4o', provider: 'OpenAI', status: '启用' },
  { name: 'DeepSeek-V3', provider: 'DeepSeek', status: '启用' },
  { name: 'Qwen-Max', provider: 'Qwen', status: '禁用' }
])
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px">
      <h2>模型管理</h2>
      <NButton type="primary">添加模型</NButton>
    </div>
    <NDataTable :columns="columns" :data="data" />
  </div>
</template>
