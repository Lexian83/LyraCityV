Vue.component("tab-home", {
  props: ["identity", "houseName", "ownerStatus"],
  data() {
    return {
      // reine Anzeige (oben)
      locked: true, // 🔒 rot (abgeschlossen) / grün (aufgeschlossen)
      bellOn: false, // 🔔 weiß (off) / rot (on)
      keypadOn: false, // ⌨️ grau (off) / weiß (on)

      // Keypad
      codeInput: "",
    };
  },
  computed: {
    displayAddress() {
      return this.houseName && this.houseName !== ""
        ? this.houseName
        : "Unbekanntes Haus";
    },
    displayOwner() {
      if (!this.ownerStatus || this.ownerStatus === "") {
        return "Unbekannt";
      }
      const v = String(this.ownerStatus).toLowerCase();
      if (v === "frei") return "Frei";
      if (v === "verkauft") return "Verkauft";
      if (v === "vermietet") return "Vermietet";
      return this.ownerStatus;
    },
  },
  methods: {
    actionRing() {
      console.log("[HOUSING] Klingeln gedrückt");
    },
    actionEnter() {
      console.log("[HOUSING] Betreten gedrückt");
    },
    actionMessage() {
      console.log("[HOUSING] Nachricht gedrückt");
    },
    actionBreakIn() {
      console.log("[HOUSING] Einbrechen gedrückt");
    },
    actionToggleLock() {
      this.locked = !this.locked;
      console.log(
        "[HOUSING] Türstatus:",
        this.locked ? "abgeschlossen" : "aufgeschlossen"
      );
    },
    press(n) {
      if (this.codeInput.length < 8) this.codeInput += String(n);
    },
    backspace() {
      this.codeInput = this.codeInput.slice(0, -1);
    },
    clearAll() {
      this.codeInput = "";
    },
    confirm() {
      console.log("[HOUSING] Code bestätigt:", this.codeInput);
    },
    setParameter(parameter, value) {
      this.identity[parameter] = value;
    },
    isActive(parameter, value) {
      return { active: this.identity[parameter] === value };
    },
  },
  template: `
    <div class="housing-home">
      <div class="left">
        <!-- STATUS DISPLAY BAR (nicht klickbar) -->
        <div class="status-bar display">
          <div class="status-indicator lock" :class="locked ? 'locked' : 'unlocked'">
            <i class="fa-solid" :class="locked ? 'fa-lock' : 'fa-lock-open'"></i>
          </div>
          <div class="status-indicator bell" :class="bellOn ? 'on' : 'off'">
            <i class="fa-regular fa-bell"></i>
          </div>
          <div class="status-indicator keypad" :class="keypadOn ? 'on' : 'off'">
            <i class="fa-regular fa-keyboard"></i>
          </div>
        </div>

        <div class="card">
          <div class="title">Adresse</div>
          <div class="value">{{ displayAddress }}</div>
        </div>
        <div class="card">
          <div class="title">Besitzer</div>
          <div class="value">{{ displayOwner }}</div>
        </div>

        <div class="divider"></div>

        <div class="actions-grid">
          <button class="btn-action" @click="actionRing">
            <i class="fa-regular fa-bell"></i>
            <span>Klingeln</span>
          </button>
          <button class="btn-action" @click="actionToggleLock">
            <i class="fa-solid fa-lock"></i>
            <span>Auf-/Zusperren</span>
          </button>
          <button class="btn-action" @click="actionMessage">
            <i class="fa-regular fa-envelope"></i>
            <span>Nachricht</span>
          </button>
          <button class="btn-action danger" @click="actionBreakIn">
            <i class="fa-solid fa-user-secret"></i>
            <span>Einbrechen</span>
          </button>
        </div>
      </div>

      <!-- Rechts: Keypad, Dummy-Inhalt etc. -->
      <div class="right">
        <div class="card">
          <div class="title">PIN-Code</div>
          <div class="keypad-display">{{ codeInput || '••••' }}</div>
          <div class="keypad-grid">
            <button v-for="n in 9" :key="n" @click="press(n)">{{ n }}</button>
            <button @click="clearAll">C</button>
            <button @click="press(0)">0</button>
            <button @click="backspace">&larr;</button>
          </div>
          <button class="btn-action" style="margin-top: 6px;" @click="confirm">
            <i class="fa-solid fa-check"></i>
            <span>Bestätigen</span>
          </button>
        </div>
      </div>
    </div>
  `,
});
