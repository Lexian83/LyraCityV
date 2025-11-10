Vue.component("tab-nose", {
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
                        {{ structureLabels[0] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[0]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[0]"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[1] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[1]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[1]"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[2] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[2]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[2]"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[3] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[3]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[3]"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[4] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[4]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[4]"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[5] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[5]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[5]"/>
                </div>
            </div>
        </div>
    `,
});
