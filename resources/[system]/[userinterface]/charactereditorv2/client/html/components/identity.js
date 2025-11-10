Vue.component("tab-identity", {
  props: ["identity", "countries"],
  methods: {
    setParameter(parameter, value) {
      this.identity[parameter] = value;
    },
    isActive(parameter, value) {
      if (this.identity[parameter] === value) {
        return { active: true };
      }

      return { active: false };
    },
  },
  watch: {},
  template: `
        <div class="options">
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[0] }}
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="text" v-model="identity.fname"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[1] }}
                    </div>
                </div>
                <div class="inputHolder">
                    <input type="text" v-model="identity.sname"/>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[2] }}
                    </div>
                </div>
                <div class="inputHolder date-wrapper">
                    <input type="date" v-model="identity.birthdate"/>
                      <i class="fa-solid fa-calendar-days"></i>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[3] }}
                    </div>
                </div>
                <div class="inputHolder">
                    <select v-model="identity.country">
                      <option disabled value="">Bitte Land auswählen</option>
                      <option v-for="country in countries" :key="country.code" :value="country.code">
                         {{ country.name }}
                      </option>
                    </select>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[4] }}
                    </div>
                    <div class="value">
                        {{ menuNamesPast[identity.past] }}
                    </div>
                </div>
                <div class="split past">
                    <button @click="setParameter('past', 1)" :class="isActive('past', 1)"><img class="icon" src="icons/past-crime.png" /></button>
                    <button @click="setParameter('past', 0)" :class="isActive('past', 0)"><img class="icon" src="icons/past-zivi.png" /></button>
                </div>
            </div>





        </div>
    `,
});
