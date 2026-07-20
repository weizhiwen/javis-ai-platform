import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { darkTheme, lightTheme } from 'naive-ui'
import type { GlobalTheme } from 'naive-ui'

export const useThemeStore = defineStore('theme', () => {
  const isDark = ref(false)

  const theme = computed<GlobalTheme | null>(() => {
    return isDark.value ? darkTheme : null
  })

  function toggleTheme() {
    isDark.value = !isDark.value
  }

  function setDark(dark: boolean) {
    isDark.value = dark
  }

  return {
    isDark,
    theme,
    toggleTheme,
    setDark
  }
})
