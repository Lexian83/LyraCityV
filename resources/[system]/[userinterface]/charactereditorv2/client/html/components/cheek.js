Vue.component("tab-cheek", {
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
                        {{ structureLabels[8] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[8]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[8]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[9] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[9]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[9]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[10] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[10]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[10]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[13] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[13]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[13]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[14] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[14]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[14]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[15] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[15]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[15]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[16] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[16]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[16]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[17] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[17]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[17]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[18] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[18]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[18]"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ structureLabels[19] }}
                    </div>
                    <div class="value">
                        {{ parseFloat(data.structure[19]).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="-1" max="1" step="0.1" v-model.number="data.structure[19]"/>
                </div>
            </div>


        </div>
    `,
});
