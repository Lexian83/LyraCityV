Vue.component("tab-eye", {
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
                        {{ structureLabels[6] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[6]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[6]"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[7] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[7]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[7]"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[11] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[11]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[11]"/>
                </div>
            </div>
        </div>
    `,
});
