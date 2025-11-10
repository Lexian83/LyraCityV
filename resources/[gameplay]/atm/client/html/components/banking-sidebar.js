Vue.component('banking-sidebar', {
  props: ['state'],
  methods: {
    nav(view){ this.$emit('navigate', view); }
  },
  template: `
  <div class="nav">
    <button :class="{active: state.ui.view==='dashboard'}" @click="nav('dashboard')">Dashboard</button>
    <button :class="{active: state.ui.view==='actions'}" @click="nav('actions')">Einzahlen/Abheben</button>
    <button :class="{active: state.ui.view==='statement'}" @click="nav('statement')">Auszug</button>
  </div>
  `
});