<script setup lang="ts">
import { NCard, NForm, NFormItem, NInput, NButton, NSwitch } from 'naive-ui'
import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()
</script>

<template>
  <div>
    <h2 style="margin-bottom: 16px">系统设置</h2>
    <NCard title="外观设置">
      <NForm label-placement="left" label-width="100">
        <NFormItem label="暗色模式">
          <NSwitch :value="themeStore.isDark" @update:value="themeStore.setDark" />
        </NFormItem>
      </NForm>
    </NCard>
  </div>
</template>
