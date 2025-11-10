Vue.component("tab-lips", {
  props: ["data"],
  methods: {
    setParameter(parameter, value) {
      this.data[parameter] = value;
      window.postMessage({ action: "updateCharacter" });
    },
  },
  watch: {
    "data.structure": function (newVal, oldVal) {
      window.postMessage({ action: "updateCharacter" });
    },
  },
  template: `
        <div class="options">
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[12] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[12]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[12]"/>
                </div>
            </div>
        </div>
    `,
});
