<script setup lang="ts">
import { NButton, NDataTable } from 'naive-ui'
import { ref } from 'vue'

const columns = [
  { title: '工具名称', key: 'name' },
  { title: '类型', key: 'type' },
  { title: '状态', key: 'status' }
]

const data = ref([
  { name: 'HTTP 请求', type: 'HTTP', status: '启用' },
  { name: '数据库查询', type: 'Database', status: '启用' },
  { name: 'Web 搜索', type: 'MCP', status: '启用' }
])
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px">
      <h2>工具管理</h2>
      <NButton type="primary">添加工具</NButton>
    </div>
    <NDataTable :columns="columns" :data="data" />
  </div>
</template>
