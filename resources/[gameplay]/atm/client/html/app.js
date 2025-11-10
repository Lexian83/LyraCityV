new Vue({
  el: '#app',
  data: {
    state: {
      open: false,
      account: { number: '--------', balance: 0 },
      statement: [],
      ui: { view: 'dashboard', busy: false, error: null }
    }
  },
  created(){
    window.addEventListener('message', (e) => {
      const d = e.data || {};
      if(d.type === 'atm:open'){
        this.state.open = true;
        if(d.view) this.state.ui.view = d.view;
        this.refreshAll();
      } else if(d.type === 'atm:close'){
        this.state.open = false;
      } else if(d.type === 'atm:update'){
        if(typeof d.balance === 'number') this.state.account.balance = d.balance;
        this.loadStatement();
      }
    });
  },
  methods: {
    setView(v){ this.state.ui.view = v; },
    closeUI(){
      this.state.open = false;
      this.postNui('atm:close', {});
    },
    toast(txt){
      // lightweight toast via console for now
      try { console.log('[ATM]', txt); } catch(e){}
    },
    postNui(event, payload){
      return fetch(`https://atm/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload || {})
      });
    },
    async fetchNui(event, payload){
      const res = await fetch(`https://atm/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload || {})
      });
      return await res.json();
    },
    async refreshAll(){
      await this.loadAccount();
      await this.loadStatement();
    },
    async loadAccount(){
      try {
        const acc = await this.fetchNui('atm:getAccount', {});
        if(acc && acc.ok){
          this.state.account.number = acc.account_number;
          this.state.account.balance = +acc.balance || 0;
        }
      } catch(e){ console.error(e); }
    },
    async loadStatement(){
      try {
        const list = await this.fetchNui('atm:getStatement', { limit: 25, offset: 0 });
        if(Array.isArray(list)) this.state.statement = list;
      } catch(e){ console.error(e); }
    }
  }
});