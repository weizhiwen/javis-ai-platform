<script setup lang="ts">
import { NCard, NGrid, NGi, NStatistic } from 'naive-ui'
</script>

<template>
  <div>
    <h2 style="margin-bottom: 24px">仪表盘</h2>
    <NGrid :cols="4" :x-gap="16" :y-gap="16">
      <NGi>
        <NCard>
          <NStatistic label="Agent 数量" :value="12" />
        </NCard>
      </NGi>
      <NGi>
        <NCard>
          <NStatistic label="对话数" :value="1024" />
        </NCard>
      </NGi>
      <NGi>
        <NCard>
          <NStatistic label="知识库" :value="8" />
        </NCard>
      </NGi>
      <NGi>
        <NCard>
          <NStatistic label="工具数" :value="36" />
        </NCard>
      </NGi>
    </NGrid>
  </div>
</template>
