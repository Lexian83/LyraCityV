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

      houseName: "Lade Hausdaten.",
      ownerStatus: "Lade Besitzerdaten...",
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

    applyHousingPayload(payload) {
      // payload von Client: { houseId, houseName, ownerStatus }
      if (!payload) return;

      if (payload.houseName && payload.houseName !== "") {
        this.houseName = payload.houseName;
      } else if (payload.houseId) {
        this.houseName = `Haus #${payload.houseId}`;
      } else {
        this.houseName = "Unbekanntes Haus";
      }

      if (
        typeof payload.ownerStatus === "string" &&
        payload.ownerStatus.trim() !== ""
      ) {
        this.ownerStatus = payload.ownerStatus;
      } else {
        this.ownerStatus = "Unbekannt";
      }
    },
  },
  mounted() {
    window.addEventListener("message", (event) => {
      const data = event.data || {};

      if (data.action === "openHousing") {
        if (!this.show) {
          this.applyHousingPayload(data);
          this.show = true;
        }
        console.log("[HOUSING][NUI] openHousing", data);
      } else if (data.action === "closeHousing") {
        this.show = false;
        console.log("[HOUSING][NUI] closeHousing");
      }
    });
  },
});
