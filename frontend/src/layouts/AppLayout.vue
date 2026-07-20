<script setup lang="ts">
import { NLayout, NLayoutSider, NLayoutHeader, NLayoutContent, NMenu, NButton, NIcon } from 'naive-ui'
import { computed, h, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useThemeStore } from '@/stores/theme'
import {
  HomeOutline,
  PeopleOutline,
  ChatbubblesOutline,
  LibraryOutline,
  GitNetworkOutline,
  CubeOutline,
  HammerOutline,
  SettingsOutline,
  SunnyOutline,
  MoonOutline
} from '@vicons/ionicons5'
import type { MenuOption } from 'naive-ui'

const themeStore = useThemeStore()
const route = useRoute()
const collapsed = ref(false)

function renderIcon(icon: any) {
  return () => h(NIcon, null, { default: () => h(icon) })
}

const menuOptions = computed<MenuOption[]>(() => [
  { label: () => h(RouterLink, { to: '/dashboard' }, { default: () => '仪表盘' }), key: 'dashboard', icon: renderIcon(HomeOutline) },
  { label: () => h(RouterLink, { to: '/agent' }, { default: () => 'Agent' }), key: 'agent', icon: renderIcon(PeopleOutline) },
  { label: () => h(RouterLink, { to: '/chat' }, { default: () => '对话' }), key: 'chat', icon: renderIcon(ChatbubblesOutline) },
  { label: () => h(RouterLink, { to: '/knowledge' }, { default: () => '知识库' }), key: 'knowledge', icon: renderIcon(LibraryOutline) },
  { label: () => h(RouterLink, { to: '/workflow' }, { default: () => '工作流' }), key: 'workflow', icon: renderIcon(GitNetworkOutline) },
  { label: () => h(RouterLink, { to: '/model' }, { default: () => '模型' }), key: 'model', icon: renderIcon(CubeOutline) },
  { label: () => h(RouterLink, { to: '/tool' }, { default: () => '工具' }), key: 'tool', icon: renderIcon(HammerOutline) },
  { label: () => h(RouterLink, { to: '/settings' }, { default: () => '设置' }), key: 'settings', icon: renderIcon(SettingsOutline) }
])

const selectedKey = computed(() => {
  const path = route.path.split('/')[1]
  return path || 'dashboard'
})
</script>

<template>
  <NLayout has-sider style="height: 100vh">
    <NLayoutSider
      bordered
      :collapsed="collapsed"
      collapse-mode="width"
      :collapsed-width="64"
      :width="220"
      show-trigger
      @collapse="collapsed = true"
      @expand="collapsed = false"
    >
      <div style="padding: 16px; text-align: center; font-size: 18px; font-weight: bold">
        {{ collapsed ? 'J' : 'Javis AI' }}
      </div>
      <NMenu
        :collapsed="collapsed"
        :collapsed-width="64"
        :collapsed-icon-size="22"
        :options="menuOptions"
        :value="selectedKey"
      />
    </NLayoutSider>
    <NLayout>
      <NLayoutHeader bordered style="padding: 0 24px; display: flex; align-items: center; justify-content: flex-end; height: 60px">
        <NButton quaternary circle @click="themeStore.toggleTheme">
          <template #icon>
            <NIcon size="20">
              <SunnyOutline v-if="themeStore.isDark" />
              <MoonOutline v-else />
            </NIcon>
          </template>
        </NButton>
      </NLayoutHeader>
      <NLayoutContent content-style="padding: 24px;" style="height: calc(100vh - 60px); overflow: auto">
        <RouterView />
      </NLayoutContent>
    </NLayout>
  </NLayout>
</template>
