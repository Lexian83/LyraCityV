Vue.config.devtools = true;
Vue.prototype.window = window;

const app = new Vue({
  el: "#app",
  data() {
    return {
      show: false,
      selection: 0,
      identity: {},
      navOptions: [
        "Home",
        "Interaction",
        "Npcs",
        "Blips",
        "Faction",
        "Faction_Perms",
      ],
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
    closeADMIN() {
      const el = document.querySelector("#app");
      el.style.transition = "opacity 0.8s ease";
      el.style.opacity = "0";
      setTimeout(() => {
        fetch(`https://${GetParentResourceName()}/LCV:ADMIN:Hide`, {
          method: "POST",
        });
      }, 800); // warte bis Fade-Out fertig
    },
  },
  mounted() {
    window.addEventListener("message", (event) => {
      let data = event.data;
      if (data.action == "openADMIN") {
        if (this.show) {
          return;
        }
        this.show = true;
        console.log("[ADMIN][CLIENT] Get Trigger to Open");
      } else if (data.action == "closeADMIN") {
        this.show = false;
        console.log("[ADMIN][CLIENT] Get Trigger to Hide");
      }
    });
  },
});
