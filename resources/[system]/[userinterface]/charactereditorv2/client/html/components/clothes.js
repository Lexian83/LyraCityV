Vue.component("tab-clothes", {
  props: ["data", "clothes", "editor"],
  // ⬇️ Eigener Zeiger nur für die Top-Liste
  data() {
    return {
      topIndex: null, // wird beim ersten Use automatisch ermittelt
    };
  },
  methods: {
    addToList() {
      // Wenn die Liste noch nicht existiert, erstelle sie
      if (!this.topList) this.topList = {};

      // Nächster Index (0,1,2,3, …)
      const nextIndex = Object.keys(this.topList).length;

      // Eintrag anlegen
      this.topList[nextIndex] = {
        comp: this.clothes.top,
        torso: this.clothes.torso,
      };

      // In der F8-Konsole ausgeben
      console.log("[LCV] Eintrag hinzugefügt:", this.topList[nextIndex]);
    },

    print() {
      if (!this.topList || Object.keys(this.topList).length === 0) {
        console.log("[LCV] Liste ist leer.");
        return;
      }

      // Sauber formatiert in F8 anzeigen, damit du’s raus-kopieren kannst
      console.log(
        "const topList = " + JSON.stringify(this.topList, null, 2) + ";"
      );
    },
    isActive(parameter, value) {
      if (this.data[parameter] === value) {
        return { active: true };
      }

      return { active: false };
    },
    decrementParameter(parameter, min, max, incrementValue) {
      this.clothes[parameter] -= incrementValue;

      if (this.clothes[parameter] < min) {
        this.clothes[parameter] = max;
      }
      if (parameter == "top") {
        this.clothes.topcolor = 0;
      }
      if (parameter == "pants") {
        this.clothes.pantsColor = 0;
      }
      if (parameter == "shoes") {
        this.clothes.shoesColor = 0;
      }
      if (parameter == "undershirt") {
        this.clothes.undershirtColor = 0;
      }
      window.postMessage({ action: "updateCharacter" });
    },
    incrementParameter(parameter, min, max, incrementValue) {
      this.clothes[parameter] += incrementValue;

      if (this.clothes[parameter] > max) {
        this.clothes[parameter] = min;
      }
      if (parameter == "top") {
        this.clothes.topcolor = 0;
      }
      if (parameter == "pants") {
        this.clothes.pantsColor = 0;
      }
      if (parameter == "shoes") {
        this.clothes.shoesColor = 0;
      }
      if (parameter == "undershirt") {
        this.clothes.undershirtColor = 0;
      }

      window.postMessage({ action: "updateCharacter" });
    },
    // --- Helper: Liste + sortierte Keys + Count ---
    _getTopListMeta() {
      const list =
        this.data.sex === 1
          ? typeof topListMale !== "undefined"
            ? topListMale
            : {}
          : typeof topListFemale !== "undefined"
          ? topListFemale
          : {};

      const keys = Object.keys(list)
        .map(Number)
        .sort((a, b) => a - b);
      return { list, keys, total: keys.length };
    },

    // --- Helper: Index passend zu aktuellen clothes ermitteln ---
    _resolveTopIndexFromCurrent() {
      const { list, keys } = this._getTopListMeta();
      for (const k of keys) {
        const e = list[k];
        if (
          e &&
          e.comp === this.clothes.top &&
          e.torso === this.clothes.torso
        ) {
          return k;
        }
      }
      // Fallback: erster Eintrag
      return keys.length ? keys[0] : null;
    },

    // --- Anwenden eines Listeneintrags auf clothes ---
    _applyTopEntryByIndex(idx) {
      const { list } = this._getTopListMeta();
      const entry = list[idx];
      if (!entry) return;

      this.topIndex = idx; // Zeiger aktualisieren
      this.clothes.top = entry.comp;
      this.clothes.torso = entry.torso;
      this.clothes.topcolor = 0; // Farbe resetten, wie bei deinen anderen Wechseln
      this.clothes.undershirt = entry.under;
      window.postMessage({ action: "updateCharacter" });

      console.log(
        `[LCV] Top @#${idx}: comp=${entry.comp}, torso=${entry.torso}`
      );
    },

    // === Dein Wunsch: zurück blättern (… 89 -> 88 …) ===
    decrementParameterTop() {
      const { keys, total } = this._getTopListMeta();
      if (!total) return;

      if (this.topIndex === null || !keys.includes(this.topIndex)) {
        this.topIndex = this._resolveTopIndexFromCurrent();
      }
      const curPos = keys.indexOf(this.topIndex);
      const prevPos = (curPos - 1 + total) % total; // wrap-around
      const newIndex = keys[prevPos];
      this._applyTopEntryByIndex(newIndex);
    },

    // === Vorwärts blättern (… 88 -> 89 …) ===
    incrementParameterTop() {
      const { keys, total } = this._getTopListMeta();
      if (!total) return;

      if (this.topIndex === null || !keys.includes(this.topIndex)) {
        this.topIndex = this._resolveTopIndexFromCurrent();
      }
      const curPos = keys.indexOf(this.topIndex);
      const nextPos = (curPos + 1) % total; // wrap-around
      const newIndex = keys[nextPos];
      this._applyTopEntryByIndex(newIndex);
    },
  },
  watch: {},
  computed: {
    // aktive Liste je nach Geschlecht
    activeTopList() {
      if (this.data.sex === 1 && typeof topListMale !== "undefined") {
        return topListMale;
      }
      if (this.data.sex === 0 && typeof topListFemale !== "undefined") {
        return topListFemale;
      }
      return {};
    },

    // Anzahl der Einträge der aktiven Liste
    topListCount() {
      return Object.keys(this.activeTopList || {}).length;
    },
  },
  template: `
        <div class="options">
        <div class="option">
         <div class="labelContainer">
                 <div class="label facetext">
                        OBERTEIL
                  </div>
            </div>
                <div class="labelContainer">
                    <div class="label">
                        MODEL
                    </div>
                    <div class="value">
                        {{ clothes.top }} | {{ topListCount }}
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameterTop()">&#8249;</button>
                    <span> {{ clothes.top }} </span>
                    <button class="arrowRight" @click="incrementParameterTop()">&#8250;</button>
                </div>

                <div class="labelContainer">
                    <div class="label">
                        MODEL FARBE
                    </div>
                    <div class="value">
                        {{ clothes.topcolor }} | {{ editor.topcolors-1 }}
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('topcolor', 0, editor.topcolors-1, 1)">&#8249;</button>
                    <span> {{ clothes.topcolor }} </span>
                    <button class="arrowRight" @click="incrementParameter('topcolor', 0, editor.topcolors-1, 1)">&#8250;</button>
                </div>

                <div class="labelContainer">
                    <div class="label">
                        UNTERHEMD
                    </div>
                    <div class="value">
                        {{ clothes.undershirt }} | 30
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('undershirt', 0, 30, 1)">&#8249;</button>
                    <span> {{ clothes.undershirt }} </span>
                    <button class="arrowRight" @click="incrementParameter('undershirt', 0, 30, 1)">&#8250;</button>
                </div>

                <div class="labelContainer">
                    <div class="label">
                        UNTERHEMD FARBE
                    </div>
                    <div class="value">
                        {{ clothes.undershirtColor }} | {{ editor.undershirtColors-1 }}
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('undershirtColor', 0, editor.undershirtColors-1, 1)">&#8249;</button>
                    <span> {{ clothes.undershirtColor }} </span>
                    <button class="arrowRight" @click="incrementParameter('undershirtColor', 0, editor.undershirtColors-1, 1)">&#8250;</button>
                </div>
              </div>

             <div class="option">
                <div class="labelContainer">
                <div class="label facetext">
                        HOSE
                  </div>
                  </div>
                  <div class="labelContainer">
                    <div class="label">
                        Model
                    </div>
                    <div class="value">
                        {{ clothes.pants }} | 150
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('pants', 0, 150, 1)">&#8249;</button>
                    <span> {{ clothes.pants }} </span>
                    <button class="arrowRight" @click="incrementParameter('pants', 0, 150, 1)">&#8250;</button>
                </div>
                <div class="labelContainer">
                    <div class="label">
                        FARBE
                    </div>
                    <div class="value">
                        {{ clothes.pantsColor }} | {{ editor.pantsColor-1 }}
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('pantsColor', 0, editor.pantsColor-1, 1)">&#8249;</button>
                    <span> {{ clothes.pantsColor }} </span>
                    <button class="arrowRight" @click="incrementParameter('pantsColor', 0, editor.pantsColor-1, 1)">&#8250;</button>
                </div>


            </div>

            <div class="option">
                <div class="labelContainer">
                <div class="label facetext">
                        SCHUHE
                  </div>
                  </div>
                  <div class="labelContainer">
                    <div class="label">
                        Model
                    </div>
                    <div class="value">
                        {{ clothes.shoes }} | 105
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('shoes', 0, 105, 1)">&#8249;</button>
                    <span> {{ clothes.shoes }} </span>
                    <button class="arrowRight" @click="incrementParameter('shoes', 0, 105, 1)">&#8250;</button>
                </div>
                <div class="labelContainer">
                    <div class="label">
                        FARBE
                    </div>
                    <div class="value">
                        {{ clothes.shoesColor }} | {{ editor.shoesColor-1 }}
                    </div>
                </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('shoesColor', 0, editor.shoesColor-1, 1)">&#8249;</button>
                    <span> {{ clothes.shoesColor }} </span>
                    <button class="arrowRight" @click="incrementParameter('shoesColor', 0, editor.shoesColor-1, 1)">&#8250;</button>
                </div>
            </div>





            <div class="option">
                <div class="labelContainer">
                    <div class="label facetext">
                        HINZUFÜGEN
                    </div>
                </div>
                <div class="label">
                        TORSO
                    </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('torso', 0, 800, 1)">&#8249;</button>
                    <span> {{ clothes.torso }} </span>
                    <button class="arrowRight" @click="incrementParameter('torso', 0, 800, 1)">&#8250;</button>
                </div>
                <div class="label">
                        TOP
                    </div>
                <div class="controls">
                    <button class="arrowLeft" @click="decrementParameter('top', 0, 800, 1)">&#8249;</button>
                    <span> {{ clothes.top }} </span>
                    <button class="arrowRight" @click="incrementParameter('top', 0, 800, 1)">&#8250;</button>
                </div>
                <div class="label">
                        LIST
                    </div>
                <div class="split">
                    <button @click="print()">PRINT</button>
                    <button @click="addToList()">ADD</button>
                </div>
            </div>











        </div>
    `,
});
