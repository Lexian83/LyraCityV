Vue.component("tab-done", {
  props: ["data", "identity", "countries"],
  methods: {},
  computed: {
    // Hilfsfunktion: Land anhand Kürzel zurückgeben
    countryName() {
      const country = this.countries.find(
        (c) => c.code === this.identity.country
      );
      return country ? country.name : "Unbekannt";
    },
  },
  template: `
        <div class="options">
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[0] }} :
                    </div>
                    <div class="value">
                        {{ identity.fname }}
                    </div>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[1] }} :
                    </div>
                    <div class="value">
                        {{ identity.sname }}
                    </div>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[2] }} :
                    </div>
                    <div class="value">
                        {{ identity.birthdate }}
                    </div>
                </div>
            </div>
            <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[3] }} :
                    </div>
                    <div class="value">
                        {{ countryName }}
                    </div>
                </div>
            </div>
             <div class="option">
                <div class="labelContainer">
                    <div class="label">
                        {{ menuNamesIdentity[4] }} :
                    </div>
                    <div class="value">
                        {{ menuNamesPast[identity.past] }}
                    </div>
                </div>
            </div>
            
        </div>
    `,
});
