Vue.component("lspd-zulassungsstelle", {
  props: ["identity"],
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
        <div class="options"><h1 style="margin:0">Hallo 👋</h1><p>Dummy-Inhalt für das LSPD Zulassungsstelle.</p>
            
        </div>
    `,
});
