<script setup lang="ts">
import { NCard, NForm, NFormItem, NInput, NButton } from 'naive-ui'
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const username = ref('')
const password = ref('')

function handleLogin() {
  router.push('/dashboard')
}
</script>

<template>
  <div style="display: flex; justify-content: center; align-items: center; height: 100vh; background: #f5f5f5">
    <NCard style="width: 400px" title="登录 Javis AI">
      <NForm @submit.prevent="handleLogin">
        <NFormItem label="用户名">
          <NInput v-model:value="username" placeholder="请输入用户名" />
        </NFormItem>
        <NFormItem label="密码">
          <NInput v-model:value="password" type="password" placeholder="请输入密码" />
        </NFormItem>
        <NButton type="primary" block attr-type="submit">登录</NButton>
      </NForm>
    </NCard>
  </div>
</template>
