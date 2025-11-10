Vue.component('banking-actions', {
  props: ['state'],
  data(){ return { amount: null, busy:false, msg:null } },
  methods: {
    async act(kind){
      if(!this.amount || this.amount <= 0) { this.msg = 'Bitte Betrag eingeben'; return; }
      this.busy = true; this.msg = null;
      try{
        const res = await this.$root.fetchNui(kind==='deposit'?'atm:deposit':'atm:withdraw', { amount: this.amount });
        if(res && res[0] === true){
          this.state.account.balance = res[1] || this.state.account.balance;
          this.$root.toast((kind==='deposit'?'Einzahlung':'Abhebung') + ' erfolgreich');
          this.amount = null;
          // refresh statement silently
          this.$root.loadStatement();
        } else {
          this.msg = (res && res[2]) || 'Fehlgeschlagen';
        }
      } catch(e){
        this.msg = 'Fehler: ' + e;
      } finally {
        this.busy = false;
      }
    }
  },
  template: `
  <div>
    <div class="card">
      <div class="sub">Betrag</div>
      <input type="number" min="1" step="1" v-model.number="amount" placeholder="z. B. 250" style="width:200px; padding:10px; border-radius:10px; border:1px solid rgba(255,255,255,.1); background:#0c0f14; color:white"/>
      <div style="display:flex; gap:8px; margin-top:12px;">
        <button class="btn success" :disabled="busy" @click="act('deposit')">Einzahlen</button>
        <button class="btn primary" :disabled="busy" @click="act('withdraw')">Abheben</button>
      </div>
      <div class="sub" v-if="msg" style="margin-top:8px; color:#ffb4b4">{{ msg }}</div>
    </div>
  </div>
  `
});