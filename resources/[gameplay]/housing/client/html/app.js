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
      ownerStatus: "",
      lockState: 0,
      secured: 0,
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
      console.log("[HOUSING][NUI] applyHousingPayload RAW =", payload);
      if (!payload) return;

      // Name / Adresse
      if (payload.houseName && payload.houseName !== "") {
        this.houseName = payload.houseName;
      } else if (payload.houseId) {
        this.houseName = `Haus #${payload.houseId}`;
      } else {
        this.houseName = "Unbekanntes Haus";
      }

      // Besitzer-Status
      if (typeof payload.ownerStatus === "string") {
        this.ownerStatus = payload.ownerStatus;
      } else {
        this.ownerStatus = "";
      }

      // Lock-State aus DB
      if (payload.lockState !== undefined && payload.lockState !== null) {
        this.lockState = Number(payload.lockState) || 0;
      } else {
        this.lockState = 0;
      }
      if (payload.secured !== undefined && payload.secured !== null) {
        this.secured = Number(payload.secured) || 0;
      } else {
        this.secured = 0;
      }

      console.log(
        "[HOUSING][NUI] resolved houseName =",
        this.houseName,
        "| ownerStatus =",
        this.ownerStatus,
        "| lockState =",
        this.lockState,
        "| secured =",
        this.secured
      );
    },
  },
  mounted() {
    window.addEventListener("message", (event) => {
      const data = event.data || {};

      if (data.action === "openHousing") {
        this.applyHousingPayload(data);
        this.show = true;
        console.log("[HOUSING][NUI] openHousing", data);
      } else if (data.action === "closeHousing") {
        this.show = false;
        console.log("[HOUSING][NUI] closeHousing");
      }
    });
  },
});
