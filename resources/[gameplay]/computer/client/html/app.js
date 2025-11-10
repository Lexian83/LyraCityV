Vue.config.devtools = true;
Vue.prototype.window = window;

const app = new Vue({
  el: "#app",
  data() {
    return {
      show: false,
      selection: 0,
      identity: { fname: "", sname: "", birthdate: "", country: "", past: 0 },
      officerName: "",
      location: "", // 👈 neu
      navOptions: ["Home", "EZ", "LSPD"],
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
    getTabComponent: function () {
      return `tab-${this.navOptions[this.selection].toLowerCase()}`;
    },
  },
  methods: {
    goNext() {
      if (this.selection >= this.navOptions.length - 1) {
        return;
      }

      this.selection += 1;
    },
    goBack() {
      if (this.selection <= 0) {
        return;
      }

      this.selection -= 1;
    },
    goTo(selection) {
      this.selection = selection;
    },
    isActive(values) {
      // Wenn ein einzelner Wert übergeben wird, mach ihn zu einem Array
      if (!Array.isArray(values)) values = [values];

      // true, wenn selection in der Liste vorkommt
      const active = values.includes(this.selection);
      return { active };
    },
    closePC() {
      const el = document.querySelector("#app");
      el.style.transition = "opacity 0.8s ease";
      el.style.opacity = "0";
      setTimeout(() => {
        fetch(`https://${GetParentResourceName()}/LCV:PC:Hide`, {
          method: "POST",
        });
      }, 800); // warte bis Fade-Out fertig
    },
  },
  mounted() {
    window.addEventListener("message", (event) => {
      let data = event.data;
      if (data.action == "openPC") {
        console.log("[PC][NUI] openPC", data.officerName, data.location);

        if (this.show) {
          return;
        }

        this.show = true;
        document.body.style.display = "block";

        if (data.officerName) {
          this.officerName = data.officerName;
        } else {
          this.officerName = "";
        }

        if (data.location) {
          this.location = data.location;
        } else {
          this.location = "";
        }

        if (data.faction == "EZ") {
          this.selection = 1;
        } else if (data.faction == "LSPD") {
          this.selection = 2;
        } else {
          this.selection = 0;
        }

        console.log(
          "[PC SYSTEM][CLIENT] Get Trigger to Open",
          data.faction,
          data.location
        );
      } else if (data.action == "closePC") {
        this.show = false;
        document.body.style.display = "none";
        console.log("[PC SYSTEM] Closed UI");
      }
    });
  },
});
