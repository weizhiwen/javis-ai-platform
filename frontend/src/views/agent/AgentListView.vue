<script setup lang="ts">
import { NButton, NDataTable, NSpace } from 'naive-ui'
import { ref } from 'vue'

const columns = [
  { title: '名称', key: 'name' },
  { title: '描述', key: 'description' },
  { title: '状态', key: 'status' },
  { title: '操作', key: 'actions' }
]

const data = ref([
  { name: '客服助手', description: '智能客服 Agent', status: '已发布' },
  { name: '代码审查', description: '代码审查 Agent', status: '草稿' }
])
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px">
      <h2>Agent 列表</h2>
      <NButton type="primary">创建 Agent</NButton>
    </div>
    <NDataTable :columns="columns" :data="data" />
  </div>
</template>
