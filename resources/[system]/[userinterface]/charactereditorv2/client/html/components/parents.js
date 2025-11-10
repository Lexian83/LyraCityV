Vue.component("tab-parents", {
  props: ["data"],
  methods: {
    isActive(parameter, value) {
      if (this.data[parameter] === value) {
        return { active: true };
      }

      return { active: false };
    },
    setParameter(parameter, value) {
      if (parameter === "sex") {
        if (value === 0) {
          this.data.faceFather = 33;
          this.data.faceMother = 45;
          this.data.skinFather = 45;
          this.data.skinMother = 45;
          this.data.skinMix = 0.5;
          this.data.faceMix = 0.5;
          this.data.facialHair = 29;
          this.data.facialHairColor1 = 0;
          this.data.eyebrows = 0;
        } else {
          this.data.faceMother = 0;
          this.data.faceFather = 0;
          this.data.skinFather = 0;
          this.data.skinMother = 0;
          this.data.skinMix = 0.5;
          this.data.faceMix = 0.5;
          this.data.facialHair = 29;
          this.data.facialHairColor1 = 0;
          this.data.eyebrows = 0;
        }
      }

      if (parameter === "preset") {
        const index = parseInt(value - 1);
        const preset =
          this.data.sex === 0 ? femalePresets[index] : malePresets[index];
        Object.keys(preset).forEach((key) => {
          this.data[key] = preset[key];
        });

        this.data.facialHair = 29;
        this.data.facialHairColor1 = 0;
        this.data.eyebrows = 0;
      } else {
        if (isNaN(value)) {
          this.data[parameter] = value;
        } else {
          this.data[parameter] = parseFloat(value);
        }
      }
      if (parameter === "faceF") {
        this.data.faceFather = value;
        this.data.skinFather = value;
      }
      if (parameter === "faceM") {
        this.data.faceMother = value;
        this.data.skinMother = value;
      }

      window.postMessage({ action: "updateCharacter" });
    },
    decrementParameter(parameter, min, max, incrementValue) {
      this.data[parameter] -= incrementValue;

      if (this.data[parameter] < min) {
        this.data[parameter] = max;
      }

      window.postMessage({ action: "updateCharacter" });
    },
    incrementParameter(parameter, min, max, incrementValue) {
      this.data[parameter] += incrementValue;

      if (this.data[parameter] > max) {
        this.data[parameter] = min;
      }

      window.postMessage({ action: "updateCharacter" });
    },
  },
  watch: {
    "data.faceMix": function (newVal, oldVal) {
      window.postMessage({ action: "updateCharacter" });
    },
    "data.skinMix": function (newVal, oldVal) {
      window.postMessage({ action: "updateCharacter" });
    },
  },
  template: `
        <div class="options">

        <div class="option">
                <div class="labelContainer">
                    <div class="label facetext">
                        GESCHLECHT
                    </div>
                    <div class="value">
                        {{ data.sex === 0 ? 'Female' : 'Male' }}
                    </div>
                </div>
                <div class="split gender">
                    <button @click="setParameter('sex', 0)" :class="isActive('sex', 0)">♀</button>
                    <button @click="setParameter('sex', 1)" :class="isActive('sex', 1)">♂</button>
                </div>
        </div>


 <div class="option">
            <div class="labelContainer">
                <div class="label facetext" style="margin-top: 6px">
                    PRESETS
                </div>
            </div>
                <div class="split-auto">
                    <button v-for="i in 6" :key="i" @click="setParameter('preset', i)">
                        {{ i }}
                    </button>
                </div>
            </div>



         <div class="option">
                <div class="labelContainer">
                    <div class="label facetext">
                        VATER
                    </div>
                    <div class="value">
                        {{faceNames[data.faceFather] }}
                    </div>
                </div>
                <div class="split-auto">
                    <button v-for="i in [...Array(21).keys(), 42, 43, 44]" :key="i" @click="setParameter('faceF', i)" :class="isActive('faceFather', i)">
                      <img class="faces" :src="'faces/' + i + '.png'" :alt="'face ' + i"/>
                    </button>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label facetext">
                        MUTTER
                    </div>
                    <div class="value">
                        {{faceNames[data.faceMother] }}
                    </div>
                </div>
                <div class="split-auto">
                    <button v-for="i in [...Array.from({ length: 21 }, (_, n) => n + 21), 45]" :key="i" @click="setParameter('faceM', i)" :class="isActive('faceMother', i)">
                        <img class="faces" :src="'faces/' + i + '.png'" :alt="'face ' + i"/>
                    </button>
                </div>
            </div>

              <div class="option">
                <div class="labelContainer">
                    <div class="label">
                       Face Mix
                    </div>
                    <div class="value">
                        {{ parseFloat(data.faceMix).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="0" max="1" step="0.1" v-model.number="data.faceMix"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                       Skin Mix
                    </div>
                    <div class="value">
                        {{ parseFloat(data.skinMix).toFixed(1) }} | 1.0
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="range" min="0.0" max="1.0" step="0.1" v-model.number="data.skinMix"/>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        Eye Color
                    </div>
                    <div class="value">
                        {{ data.eyes }} | 30
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('eyes', 0, 30, 1)">&#8249;</button>
                    <span> {{ data.eyes }} </span>
                    <button class="arrowRight" @click="incrementParameter('eyes', 0, 30, 1)">&#8250;</button>
                </div>
            </div>
        </div>
    `,
});
