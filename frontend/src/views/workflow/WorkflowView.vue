<script setup lang="ts">
import { NButton, NDataTable } from 'naive-ui'
import { ref } from 'vue'

const columns = [
  { title: '名称', key: 'name' },
  { title: '描述', key: 'description' },
  { title: '节点数', key: 'nodeCount' },
  { title: '状态', key: 'status' }
]

const data = ref([
  { name: '客服工作流', description: '自动客服处理流程', nodeCount: 5, status: '已发布' },
  { name: '数据处理', description: '数据清洗与转换', nodeCount: 8, status: '草稿' }
])
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px">
      <h2>工作流</h2>
      <NButton type="primary">创建工作流</NButton>
    </div>
    <NDataTable :columns="columns" :data="data" />
  </div>
</template>
