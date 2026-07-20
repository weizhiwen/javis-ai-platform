<script setup lang="ts">
import { NCard, NForm, NFormItem, NInput, NButton } from 'naive-ui'

</script>

<template>
  <div>
    <h2 style="margin-bottom: 16px">Agent 编辑</h2>
    <NCard>
      <NForm label-placement="left" label-width="80">
        <NFormItem label="名称">
          <NInput placeholder="请输入 Agent 名称" />
        </NFormItem>
        <NFormItem label="描述">
          <NInput type="textarea" placeholder="请输入描述" />
        </NFormItem>
        <NFormItem label="系统提示词">
          <NInput type="textarea" :rows="6" placeholder="请输入系统提示词" />
        </NFormItem>
        <NFormItem>
          <NButton type="primary">保存</NButton>
        </NFormItem>
      </NForm>
    </NCard>
  </div>
</template>
