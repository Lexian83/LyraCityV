Vue.config.devtools = true;
Vue.prototype.window = window;

const app = new Vue({
  el: "#app",
  data() {
    return {
      show: false,
      selection: 0,
      data: {
        sex: 0,
        faceFather: 33,
        faceMother: 45,
        skinFather: 45,
        skinMother: 45,
        faceMix: 0.5,
        skinMix: 0.5,
        structure: new Array(20).fill(0),
        hair: 11,
        hairColor1: 5,
        hairColor2: 2,
        hairOverlay: "",
        facialHair: 29,
        facialHairColor1: 62,
        facialHairOpacity: 0,
        eyebrows: 0,
        eyebrowsOpacity: 1,
        eyebrowsColor1: 0,
        eyes: 0,
        opacityOverlays: [],
        colorOverlays: [],
      },
      editor: {
        topcolors: 0,
        undershirtColors: 0,
        shoesColor: 0,
        pantsColor: 0,
      },
      identity: { fname: "", sname: "", birthdate: "", country: "", past: 0 },
      clothes: {
        torso: 0,
        top: 0,
        topcolor: 0,
        undershirt: 0,
        undershirtColor: 0,
        shoes: 0,
        shoesColor: 0,
        pants: 0,
        pantsColor: 0,
      },
      navOptions: [
        "Identity",
        "Parents",
        "Structure",
        "Hair",
        "Overlays",
        "Decor",
        "Done",
        "Nose",
        "Eye",
        "Lips",
        "Cheek",
        "clothes",
      ],
      countries: [
        { code: "DE", name: "Deutschland" },
        { code: "AT", name: "Österreich" },
        { code: "CH", name: "Schweiz" },
        { code: "US", name: "Vereinigte Staaten" },
        { code: "GB", name: "Vereinigtes Königreich" },
        { code: "FR", name: "Frankreich" },
        { code: "IT", name: "Italien" },
        { code: "ES", name: "Spanien" },
        { code: "PT", name: "Portugal" },
        { code: "PL", name: "Polen" },
        { code: "NL", name: "Niederlande" },
        { code: "BE", name: "Belgien" },
        { code: "SE", name: "Schweden" },
        { code: "NO", name: "Norwegen" },
        { code: "FI", name: "Finnland" },
        { code: "DK", name: "Dänemark" },
        { code: "CZ", name: "Tschechien" },
        { code: "HU", name: "Ungarn" },
        { code: "GR", name: "Griechenland" },
        { code: "TR", name: "Türkei" },
        { code: "RU", name: "Russland" },
        { code: "CN", name: "China" },
        { code: "JP", name: "Japan" },
        { code: "KR", name: "Südkorea" },
        { code: "BR", name: "Brasilien" },
        { code: "CA", name: "Kanada" },
        { code: "AU", name: "Australien" },
        { code: "NZ", name: "Neuseeland" },
        { code: "IN", name: "Indien" },
        { code: "MX", name: "Mexiko" },
        { code: "ZA", name: "Südafrika" },
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
    setReady() {
      if (this.show) {
        return;
      }

      this.show = true;
      this.updateCharacter();
      window.postMessage({ action: "character:ReadyDone" });
      console.log("Hallo aus der NUI!");
    },
    setData(oldData) {
      if (!oldData) {
        this.updateCharacter();
        return;
      }

      this.data = oldData;
      this.updateCharacter();
    },
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
    updateCharacter() {
      const isFemale = this.data.sex === 0;
      this.data.hairOverlay = isFemale
        ? femaleHairOverlays[this.data.hair]
        : maleHairOverlays[this.data.hair];

      if (isFemale) {
        this.data.facialHair = 30;
        this.data.facialHairOpacity = 0;
      }

      // Update Floats
      this.data.skinMix = parseFloat(this.data.skinMix);
      this.data.faceMix = parseFloat(this.data.faceMix);

      fetch(`https://${GetParentResourceName()}/character:Sync`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          data: this.data,
          clothes: this.clothes ?? {},
          identity: this.identity ?? {},
        }),
      });
      console.log("app.js:FUNCTION:updateCharacter");
    },
    resetSelection() {
      this.selection = 0;
    },
    isActive(values) {
      // Wenn ein einzelner Wert übergeben wird, mach ihn zu einem Array
      if (!Array.isArray(values)) values = [values];

      // true, wenn selection in der Liste vorkommt
      const active = values.includes(this.selection);
      return { active };
    },
    characterDone() {
      fetch(`https://${GetParentResourceName()}/character:Done`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          data: this.data,
          clothes: this.clothes ?? {},
          identity: this.identity ?? {},
        }),
      });
      console.log("app.js:FUNCTION:characterDone");
    },
    characterCancel() {
      fetch(`https://${GetParentResourceName()}/character:Cancel`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          data: this.data,
          clothes: this.clothes ?? {},
          identity: this.identity ?? {},
        }),
      });
      console.log("app.js:FUNCTION:characterCancel");
    },
  },
  mounted() {
    //this.$root.$on("updateCharacter", this.updateCharacter);
    //this.$root.$on("resetSelection", this.resetSelection);

    window.addEventListener("message", (event) => {
      let data = event.data;
      if (data.action == "updateCharacter") {
        this.updateCharacter();
        console.log("app.js:EVENT:updateCharacter");
      }
      if (data.action == "resetSelection") {
        this.resetSelection();
        console.log("app.js:EVENT:resetSelection");
      }
    });

    opacityOverlays.forEach((overlay) => {
      const overlayData = { ...overlay };
      overlayData.value = 0;
      delete overlayData.key;
      delete overlayData.max;
      delete overlayData.min;
      delete overlayData.label;
      delete overlayData.increment;

      this.data.opacityOverlays.push(overlayData);
    });

    colorOverlays.forEach((overlay) => {
      const overlayData = { ...overlay };
      overlayData.value = 0;
      delete overlayData.key;
      delete overlayData.max;
      delete overlayData.min;
      delete overlayData.label;
      delete overlayData.increment;

      this.data.colorOverlays.push(overlayData);
    });

    window.addEventListener("message", (event) => {
      let data = event.data;
      if (data.action == "openEditor") {
        this.setReady();
        this.setData();
        console.log("app.js:EVENTLISTENER:openEditor");
      } else if (data.action == "closeEditor") {
        this.show = false;
        console.log("app.js:EVENTLISTENER:NOT openEditor");
      }
    });

    window.addEventListener("message", (e) => {
      const { action, value } = e.data || {};
      if (action == "Editor:updateTopColors") {
        this.editor.topcolors = value;
      }
      if (action == "Editor:updateUndershirtColors") {
        this.editor.undershirtColors = value;
      }
      if (action == "Editor:updateShoesColors") {
        this.editor.shoesColor = value;
      }
      if (action == "Editor:updatePantsColors") {
        this.editor.pantsColor = value;
      }
    });
  },
});
