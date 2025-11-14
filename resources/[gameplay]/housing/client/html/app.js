Vue.config.devtools = true;
Vue.prototype.window = window;

const app = new Vue({
  el: "#app",
  data() {
    return {
      show: false,
      selection: 0,
      identity: { fname: "", sname: "", birthdate: "", country: "", past: 0 },
      navOptions: ["Home"],

      houseName: "Lade Hausdaten...",
    };
  },
  computed: {
    isInactiveNext() {
      if (this.selection >= this.navOptions.length - 1) {
        return { inactive: true };
      }
      return { inactive: false };
    },
    isInactiveBack() {
      if (this.selection <= 0) {
        return { inactive: true };
      }
      return { inactive: false };
    },
    getTabComponent() {
      return `tab-${this.navOptions[this.selection].toLowerCase()}`;
    },
  },
  methods: {
    goNext() {
      if (this.selection >= this.navOptions.length - 1) return;
      this.selection += 1;
    },
    goBack() {
      if (this.selection <= 0) return;
      this.selection -= 1;
    },
    goTo(selection) {
      this.selection = selection;
    },
    isActive(values) {
      if (!Array.isArray(values)) values = [values];
      const active = values.includes(this.selection);
      return { active };
    },
    closePhone() {
      const el = document.querySelector("#app");
      el.style.transition = "opacity 0.8s ease";
      el.style.opacity = "0";
      setTimeout(() => {
        fetch(`https://${GetParentResourceName()}/LCV:Housing:Hide`, {
          method: "POST",
        });
      }, 800);
    },

    // 🔍 Kleine Hilfsfunktion: irgend einen Key tief im Objekt finden
    deepFindKey(obj, keyNames) {
      if (!obj || typeof obj !== "object") return undefined;

      // falls Array → alle Elemente durchsuchen
      if (Array.isArray(obj)) {
        for (let i = 0; i < obj.length; i++) {
          const res = this.deepFindKey(obj[i], keyNames);
          if (res !== undefined) return res;
        }
        return undefined;
      }

      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        const v = obj[k];

        // direkter Treffer?
        if (keyNames.includes(k)) {
          if (typeof v === "string" || typeof v === "number") return v;
        }

        // rekursiv in verschachtelten Objekten weiter suchen
        if (v && typeof v === "object") {
          const res = this.deepFindKey(v, keyNames);
          if (res !== undefined) return res;
        }
      }

      return undefined;
    },

    applyHousingPayload(rawPayload) {
      if (!rawPayload) return;

      // Debug: einmal halbwegs lesbar ausgeben
      try {
        console.log(
          "[HOUSING][NUI] applyHousingPayload RAW = " +
            JSON.stringify(rawPayload)
        );
      } catch (e) {
        console.log(
          "[HOUSING][NUI] applyHousingPayload RAW (fallback)",
          rawPayload
        );
      }

      // 1. Direkt versuchen: data.houseName / data.houseId
      let directName = rawPayload.houseName;
      let directId = rawPayload.houseId;

      // 2. Wenn es ein verschachteltes payload gibt → bevorzugen
      const inner =
        rawPayload.payload && typeof rawPayload.payload === "object"
          ? rawPayload.payload
          : rawPayload;

      if (inner && typeof inner === "object") {
        if (!directName && inner.houseName) directName = inner.houseName;
        if (!directId && inner.houseId) directId = inner.houseId;
      }

      // 3. Wenn wir immer noch nix haben → deep search
      let deepName = this.deepFindKey(rawPayload, [
        "houseName",
        "address",
        "name",
        "street",
      ]);
      let deepId = this.deepFindKey(rawPayload, ["houseId", "id", "houseid"]);

      let finalName = directName || deepName;
      let finalId = directId || deepId;

      if (finalName && finalName !== "") {
        this.houseName = String(finalName);
      } else if (finalId) {
        this.houseName = "Haus #" + String(finalId);
      } else {
        this.houseName = "Unbekanntes Haus";
      }

      console.log(
        "[HOUSING][NUI] resolved houseName = " +
          this.houseName +
          " (id=" +
          String(finalId || "n/a") +
          ")"
      );
    },
  },
  mounted() {
    window.addEventListener("message", (event) => {
      const data = event.data || {};

      try {
        console.log("[HOUSING][NUI] window.message = " + JSON.stringify(data));
      } catch (e) {
        console.log("[HOUSING][NUI] window.message (fallback)", data);
      }

      if (data.action === "openHousing") {
        this.applyHousingPayload(data);
        this.show = true;
      } else if (data.action === "closeHousing") {
        this.show = false;
        console.log("[HOUSING][NUI] closeHousing");
      }
    });
  },
});
