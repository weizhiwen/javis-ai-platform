<script setup lang="ts">
import { NCard, NInput, NButton, NScrollbar } from 'naive-ui'
import { ref } from 'vue'

const messages = ref([
  { role: 'user', content: '你好' },
  { role: 'assistant', content: '你好！我是 Javis AI 助手，有什么可以帮助你的吗？' }
])
const inputValue = ref('')
</script>

<template>
  <div style="display: flex; flex-direction: column; height: calc(100vh - 120px)">
    <NCard style="flex: 1; overflow: hidden">
      <NScrollbar style="max-height: 100%">
        <div v-for="(msg, index) in messages" :key="index" style="margin-bottom: 16px">
          <div :style="{ textAlign: msg.role === 'user' ? 'right' : 'left' }">
            <NCard :style="{ display: 'inline-block', maxWidth: '70%', textAlign: 'left' }">
              {{ msg.content }}
            </NCard>
          </div>
        </div>
      </NScrollbar>
    </NCard>
    <div style="margin-top: 16px; display: flex; gap: 8px">
      <NInput v-model:value="inputValue" placeholder="输入消息..." style="flex: 1" />
      <NButton type="primary">发送</NButton>
    </div>
  </div>
</template>
