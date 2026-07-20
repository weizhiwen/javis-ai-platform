<script setup lang="ts">
import { NButton, NDataTable } from 'naive-ui'
import { ref } from 'vue'

const columns = [
  { title: '名称', key: 'name' },
  { title: '文档数', key: 'docCount' },
  { title: '操作', key: 'actions' }
]

const data = ref([
  { name: '产品文档', docCount: 24 },
  { name: '技术手册', docCount: 18 }
])
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px">
      <h2>知识库</h2>
      <NButton type="primary">创建知识库</NButton>
    </div>
    <NDataTable :columns="columns" :data="data" />
  </div>
</template>
