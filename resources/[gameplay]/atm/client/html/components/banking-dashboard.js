Vue.component('banking-dashboard', {
  props: ['state'],
  computed: {
    account(){ return this.state.account || { number:'--------', balance:0 } }
  },
  template: `
  <div>
    <div class="cards">
      <div class="card">
        <div class="sub">Kontonummer</div>
        <div class="kpi">{{ account.number }}</div>
      </div>
      <div class="card">
        <div class="sub">Kontostand</div>
        <div class="kpi">{{ account.balance.toLocaleString('de-DE') }} $</div>
      </div>
      <div class="card">
        <div class="sub">Aktionen</div>
        <div style="display:flex; gap:8px; margin-top:8px;">
          <button class="btn success" @click="$emit('navigate','actions')">Einzahlen</button>
          <button class="btn primary" @click="$emit('navigate','actions')">Abheben</button>
        </div>
      </div>
    </div>
  </div>
  `
});