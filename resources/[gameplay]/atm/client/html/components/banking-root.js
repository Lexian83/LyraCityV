Vue.component('banking-root', {
  props: ['state'],
  template: `
  <div class="layout">
    <div class="sidebar">
      <div class="brand">
        <div class="logo"></div>
        <div>LyraCityV Bank</div>
      </div>
      <banking-sidebar :state="state" @navigate="$emit('navigate', $event)"></banking-sidebar>
      <div style="margin-top:auto" class="footer">Drücke ESC zum Schließen</div>
    </div>

    <div class="content">
      <div class="toolbar">
        <div class="title">
          <template v-if="state.ui.view==='dashboard'">Übersicht</template>
          <template v-else-if="state.ui.view==='actions'">Aktionen</template>
          <template v-else-if="state.ui.view==='statement'">Auszug</template>
        </div>
        <div class="actions">
          <button class="btn" @click="$emit('navigate','dashboard')">Übersicht</button>
          <button class="btn" @click="$emit('navigate','actions')">Aktionen</button>
          <button class="btn" @click="$emit('navigate','statement')">Auszug</button>
          <button class="btn danger" @click="$emit('close')">Schließen</button>
        </div>
      </div>

      <banking-dashboard v-if="state.ui.view==='dashboard'" :state="state" />
      <banking-actions v-else-if="state.ui.view==='actions'" :state="state" />
      <banking-statement v-else-if="state.ui.view==='statement'" :state="state" />
    </div>
  </div>
  `
});