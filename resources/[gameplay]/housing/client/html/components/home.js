Vue.component("tab-home", {
  props: [
    "identity",
    "houseName",
    "ownerStatus",
    "ownerName", // 👈
    "lockState",
    "secured",
    "pincode",
    "isOwner",
  ],
  data() {
    return {
      bellOn: false,
      keypadOn: false,
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
      // 1. Priorität: konkreter Besitzername
      if (this.ownerName && this.ownerName !== "") {
        return this.ownerName;
      }

      // 2. Fallback: Status-Text
      if (!this.ownerStatus || this.ownerStatus === "") {
        return "Unbekannt";
      }
      const v = String(this.ownerStatus).toLowerCase();
      if (v === "frei") return "Frei";
      if (v === "verkauft") return "Verkauft";
      if (v === "vermietet") return "Vermietet";
      return this.ownerStatus;
    },

    // 1 = locked, 0 = unlocked
    isLocked() {
      return Number(this.lockState) === 1;
    },

    // 1 = secured → Glocke rot
    isSecured() {
      return Number(this.secured) === 1;
    },

    // pincode > 0 → Keyboard weiß
    isPincodeSet() {
      return Number(this.pincode) > 0;
    },
  },
  methods: {
    actionRing() {
      console.log("[HOUSING] Klingeln gedrückt");
      // später: Server-Event
    },
    actionEnter() {
      console.log("[HOUSING] Betreten gedrückt");
      // später: HouseManager-Enter-Logic
    },
    actionMessage() {
      console.log("[HOUSING] Nachricht gedrückt");
    },
    actionBreakIn() {
      console.log("[HOUSING] Einbrechen gedrückt");
    },

    actionToggleLock() {
      const newState = this.isLocked ? 0 : 1;

      console.log(
        "[HOUSING] Türstatus-Button → neuer Zustand:",
        newState === 1 ? "abgeschlossen (1)" : "aufgeschlossen (0)"
      );

      this.$emit("update-lock", newState);

      try {
        fetch(`https://${GetParentResourceName()}/LCV:Housing:ToggleLock`, {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify({ state: newState }),
        });
      } catch (e) {
        console.error("[HOUSING] ToggleLock fetch error", e);
      }
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
        <!-- STATUS DISPLAY BAR: nur sichtbar wenn isOwner -->
        <div class="status-bar display" v-if="isOwner">
          <div
            class="status-indicator lock"
            :class="isLocked ? 'locked' : 'unlocked'"
          >
            <i class="fa-solid" :class="isLocked ? 'fa-lock' : 'fa-lock-open'"></i>
          </div>
          <div class="status-indicator bell" :class="isSecured ? 'on' : 'off'">
            <i class="fa-regular fa-bell"></i>
          </div>
          <div class="status-indicator keypad" :class="isPincodeSet ? 'on' : 'off'">
            <i class="fa-regular fa-keyboard"></i>
          </div>
        </div>

        <!-- Info-Karten -->
        <div class="card">
          <div class="title">Adresse</div>
          <div class="value">{{ displayAddress }}</div>
        </div>
        <div class="card">
          <div class="title">Besitzer</div>
          <div class="value">{{ displayOwner }}</div>
        </div>

        <div class="divider"></div>

        <!-- 4er-Button-Block -->
        <div class="actions-grid">
          <button class="btn-action" @click="actionRing">
            <i class="fa-regular fa-bell"></i>
            <span>Klingeln</span>
          </button>
          <button class="btn-action" @click="actionToggleLock" v-if="isOwner">
            <i class="fa-solid" :class="isLocked ? 'fa-lock-open' : 'fa-lock'"></i>
            <span>{{ isLocked ? 'Aufschließen' : 'Abschließen' }}</span>
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

        <!-- Betreten extra darunter -->
        <div style="margin-top:8px;">
          <button class="btn-enter" @click="actionEnter">
            <i class="fa-solid fa-door-open"></i>
            <span>Betreten</span>
          </button>
        </div>
      </div>

      <div class="right">
        <div class="pin-box">
          <div class="pin-label">Codeeingabe</div>
          <div class="pin-display">
            {{ codeInput ? codeInput.replace(/./g, "•") : "••••" }}
          </div>
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
            <button class="key subtle" @click="clearAll">CLR</button>
            <button class="key" @click="press(0)">0</button>
            <button class="key subtle" @click="backspace">DEL</button>
          </div>
          <button class="btn-confirm" @click="confirm">
            <i class="fa-solid fa-check"></i>
            <span>Code bestätigen</span>
          </button>
        </div>
      </div>
    </div>
  `,
});
