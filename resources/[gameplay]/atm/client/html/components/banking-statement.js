Vue.component('banking-statement', {
  props: ['state'],
  computed:{
    items(){ return this.state.statement || [] }
  },
  template: `
  <div class="card" style="overflow:auto;">
    <table class="table">
      <thead>
        <tr>
          <th>Datum</th>
          <th>Art</th>
          <th>Betrag</th>
          <th>Von</th>
          <th>Nach</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="it in items" :key="it.id">
          <td>{{ new Date(it.created_at).toLocaleString('de-DE') }}</td>
          <td>
            <span class="badge" :class="it.kind==='deposit' || it.kind==='transfer_in' ? 'pos' : 'neg'">
              {{ it.kind }}
            </span>
          </td>
          <td>{{ (it.amount||0).toLocaleString('de-DE') }} $</td>
          <td>{{ it.source || '-' }}</td>
          <td>{{ it.destination || '-' }}</td>
        </tr>
      </tbody>
    </table>
  </div>
  `
});