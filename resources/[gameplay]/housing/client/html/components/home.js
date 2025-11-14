Vue.component("tab-home", {
  props: ["identity"],
  data() {
    return {
      house: {
        address: "Musterstraße 12, 12345 Lyra City",
        owner: "Max Mustermann",
      },
      // reine Anzeige (oben)
      locked: true, // 🔒 rot (abgeschlossen) / grün (aufgeschlossen)
      bellOn: false, // 🔔 weiß (off) / rot (on)
      keypadOn: false, // ⌨️ grau (off) / weiß (on)

      // Keypad
      codeInput: "",
    };
  },
  computed: {
    lockLabel() {
      return this.locked ? "Aufschließen" : "Abschließen";
    },
    lockIcon() {
      return this.locked ? "fa-lock-open" : "fa-lock";
    }, // für Button im Grid
  },
  methods: {
    // Actions – aktuell nur Dummy-Logs
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

    // Lock-Status nur lokal toggeln (Dummy) – wird jetzt über Button im Grid getriggert
    actionToggleLock() {
      this.locked = !this.locked;
      console.log(
        "[HOUSING] Türstatus:",
        this.locked ? "abgeschlossen" : "aufgeschlossen"
      );
    },

    // Numpad
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
          <div class="value">{{ house.address }}</div>
        </div>
        <div class="card">
          <div class="title">Besitzer</div>
          <div class="value">{{ house.owner }}</div>
        </div>

        <div class="divider"></div>

        <!-- 4er-Grid: Klingeln, Auf-/Zu, Nachricht, Einbrechen -->
        <div class="actions-grid">
          <button class="btn-action" @click="actionRing">
            <i class="fa-regular fa-bell"></i>
            <span>Klingeln</span>
          </button>

          <!-- getauscht: Lock-Toggle jetzt im Grid -->
          <button class="btn-action" @click="actionToggleLock">
            <i class="fa-solid" :class="lockIcon"></i>
            <span>{{ lockLabel }}</span>
          </button>

          <button class="btn-action" @click="actionMessage">
            <i class="fa-regular fa-message"></i>
            <span>Nachricht</span>
          </button>
          <button class="btn-action danger" @click="actionBreakIn">
            <i class="fa-solid fa-mask"></i>
            <span>Einbrechen</span>
          </button>
        </div>

        <!-- Einzelner großer Button: Betreten -->
        <button class="btn-enter" @click="actionEnter">
          <i class="fa-solid fa-door-open"></i>
          <span>Betreten</span>
        </button>
      </div>

      <div class="right">
        <div class="pin-box">
          <div class="pin-label">Codeeingabe</div>
          <div class="pin-display">{{ codeInput.replace(/./g, "•") }}</div>
          <div class="keypad-grid">
            <button class="key" @click="press(1)">1</button>
            <button class="key" @click="press(2)">2</button>
            <button class="key" @click="press(3)">3</button>
            <button class="key" @click="press(4)">4</button>
            <button class="key" @click="press(5)">5</button>
            <button class="key" @click="press(6)">6</button>
            <button class="key" @click="press(7)">7</button>
            <button class="key" @click="press(8)">8</button>
            <button class="key" @click="press(9)">9</button>
            <button class="key subtle" @click="clearAll">C</button>
            <button class="key" @click="press(0)">0</button>
            <button class="key subtle" @click="backspace"><i class="fa-solid fa-delete-left"></i></button>
          </div>
          <button class="btn-confirm" @click="confirm">
            <i class="fa-solid fa-check"></i> Bestätigen
          </button>
        </div>
      </div>
    </div>
  `,
});
