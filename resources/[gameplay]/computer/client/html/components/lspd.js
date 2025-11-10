Vue.component("tab-lspd", {
  props: ["identity", "officer", "location"],
  data() {
    return {
      selection: 0,
      navOptions: [
        "Home",
        "Dispatch",
        "Meldungen",
        "Personen",
        "Akten",
        "Leitstelle",
        "Blitzer",
        "Zulassungsstelle",
        "Verwaltung",
      ],
      time: "",
      date: "",
      clockInterval: null,
    };
  },
  computed: {
    getTabComponentLSPD() {
      return `lspd-${this.navOptions[this.selection].toLowerCase()}`;
    },
    employeeName() {
      return this.officer && this.officer.length > 0
        ? this.officer
        : "Unbekannt";
    },
    stationName() {
      return this.location && this.location.length > 0
        ? this.location
        : "Unbekannt";
    },
  },
  methods: {
    setPage(index) {
      this.selection = index;
    },
    isNavActive(index) {
      return {
        active: this.selection === index,
      };
    },
    updateClock() {
      const now = new Date();
      const dd = String(now.getDate()).padStart(2, "0");
      const mm = String(now.getMonth() + 1).padStart(2, "0");
      const yyyy = now.getFullYear();
      const hh = String(now.getHours()).padStart(2, "0");
      const min = String(now.getMinutes()).padStart(2, "0");
      const ss = String(now.getSeconds()).padStart(2, "0");

      this.date = `${dd}.${mm}.${yyyy}`;
      this.time = `${hh}:${min}:${ss}`;
    },
  },
  mounted() {
    this.updateClock();
    this.clockInterval = setInterval(this.updateClock, 1000);
  },
  beforeDestroy() {
    if (this.clockInterval) {
      clearInterval(this.clockInterval);
    }
  },
  template: `
    <div class="options lspd-root">
      <!-- Top Navigation -->
      <div class="factionNav">
        <div class="factionBranding">
          Lyra Systems | LSPD | V.0.1.12
        </div>
        <div class="navOptions">
          <div
            v-for="(item, index) in navOptions"
            :key="index"
            class="navOption"
            :class="isNavActive(index)"
            @click="setPage(index)"
          >
            {{ item }}
          </div>
        </div>
      </div>

      <!-- Header mit Zeit / Datum / Mitarbeiter / Dienststelle -->
      <div class="lspd-header">
        <!-- Linke Seite: Zeit & Datum -->
        <div class="lspd-header-left-group">
          <div class="lspd-header-side">
            <div class="label">Zeit</div>
            <div class="value">{{ time }}</div>
            <div class="label">Datum</div>
            <div class="value">{{ date }}</div>
          </div>

          <!-- Mitarbeiter -->
          <div class="lspd-header-side">
            <div class="label">Mitarbeiter</div>
            <div class="value">{{ employeeName }}</div>
          </div>
        </div>

        <!-- Mitte: Logo -->
        <div class="lspd-header-center">
          <img src="icons/lspd.png" alt="LSPD" class="lspd-logo" />
        </div>

        <!-- Rechte Seite: Dienststelle (aus location) + Platzhalter -->
        <div class="lspd-header-side lspd-header-right">
          <div class="label">Dienststelle</div>
          <div class="value">{{ stationName }}</div>
          <div class="label">Dienststatus</div>
          <div class="value">10-8 | Einsatzbereit</div>
          <div class="label">System</div>
          <div class="value">Connected</div>
        </div>
      </div>

      <!-- Inhalt -->
      <component
        :is="getTabComponentLSPD"
        :identity="identity"
      ></component>
    </div>
  `,
});
