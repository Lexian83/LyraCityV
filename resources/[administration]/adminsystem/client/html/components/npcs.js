// Szenario-Optionen für NPCs (Label + Original-Name)
const NPC_SCENARIOS = [
  { value: "", label: "Kein Scenario" },
  { value: "WORLD_HUMAN_AA_COFFEE", label: "Kaffee trinken" },
  { value: "WORLD_HUMAN_AA_SMOKE", label: "Rauchen" },
  { value: "WORLD_HUMAN_BINOCULARS", label: "Mit Fernglas schauen" },
  { value: "WORLD_HUMAN_CLIPBOARD", label: "Mit Klemmbrett stehen" },
  { value: "WORLD_HUMAN_COP_IDLES", label: "Cop Idle" },
  { value: "WORLD_HUMAN_DRINKING", label: "Trinken" },
  { value: "WORLD_HUMAN_DRUG_DEALER", label: "Drogendealer (soft)" },
  { value: "WORLD_HUMAN_DRUG_DEALER_HARD", label: "Drogendealer (hard)" },
  { value: "WORLD_HUMAN_GUARD_STAND", label: "Wache stehen" },
  { value: "WORLD_HUMAN_GUARD_PATROL", label: "Wache patrouillieren" },
  { value: "WORLD_HUMAN_HAMMERING", label: "Hämmern / Bauarbeiter" },
  { value: "WORLD_HUMAN_HANG_OUT_STREET", label: "An der Ecke herumstehen" },
  { value: "WORLD_HUMAN_JOG_STANDING", label: "Auf der Stelle joggen" },
  { value: "WORLD_HUMAN_LEANING", label: "An Wand lehnen" },
  { value: "WORLD_HUMAN_MOBILE_FILM_SHOCKING", label: "Mit Handy filmen" },
  { value: "WORLD_HUMAN_MUSICIANS", label: "Musiker spielen" },
  { value: "WORLD_HUMAN_PARTYING", label: "Party machen" },
  { value: "WORLD_HUMAN_PICNIC", label: "Picknick" },
  { value: "WORLD_HUMAN_PUSH_UPS", label: "Liegestütze" },
  { value: "WORLD_HUMAN_SIT_UPS", label: "Sit-Ups" },
  { value: "WORLD_HUMAN_SMOKING", label: "Rauchen (allgemein)" },
  { value: "WORLD_HUMAN_SMOKING_POT", label: "Kiffen" },
  { value: "WORLD_HUMAN_STAND_IMPATIENT", label: "Ungeduldig warten" },
  { value: "WORLD_HUMAN_STAND_MOBILE", label: "Am Handy stehen" },
  { value: "WORLD_HUMAN_STAND_MOBILE_UPRIGHT", label: "Aufrecht am Handy" },
  { value: "WORLD_HUMAN_STUPOR", label: "Besoffen herumstehen" },
  { value: "WORLD_HUMAN_SUNBATHE_BACK", label: "Sonnen (Rücken)" },
  { value: "WORLD_HUMAN_SUNBATHE", label: "Sonnen (Bauch)" },
  { value: "WORLD_HUMAN_TENNIS_PLAYER", label: "Tennis-Posen" },
  { value: "WORLD_HUMAN_TOURIST_MAP", label: "Tourist mit Karte" },
  { value: "WORLD_HUMAN_YOGA", label: "Yoga" },
  { value: "PROP_HUMAN_SEAT_CHAIR", label: "Sitzen: Stuhl" },
  { value: "PROP_HUMAN_SEAT_BAR", label: "Sitzen: Bar" },
  { value: "PROP_HUMAN_SEAT_BENCH", label: "Sitzen: Bank" },
  { value: "PROP_HUMAN_SEAT_DECKCHAIR", label: "Sitzen: Liegestuhl" },
  { value: "PROP_HUMAN_SEAT_IMPOUND", label: "Sitzen: Impound" },
  { value: "PROP_HUMAN_SEAT_SEWING", label: "Nähmaschine" },
  { value: "PROP_HUMAN_SEAT_COMPUTER", label: "Am Computer sitzen" },
];

Vue.component("tab-npcs", {
  props: ["identity"],

  data() {
    return {
      loading: true,
      error: null,
      npcs: [],

      scenarioOptions: NPC_SCENARIOS,

      // Add-Form
      addForm: {
        name: "",
        model: "",
        scenario: "",
        interactionType: "",
        interactable: true,
        autoGround: false,
        groundOffset: 0.1,
        zOffset: 0.0,
        x: null,
        y: null,
        z: null,
        heading: 0.0,
      },
      addError: null,
      posLoading: false,

      // Delete-Confirm
      deleteConfirm: {
        visible: false,
        row: null,
        busy: false,
        error: null,
      },

      // Edit-Dialog
      editDialog: {
        visible: false,
        busy: false,
        error: null,
        form: {
          id: null,
          name: "",
          model: "",
          scenario: "",
          interactionType: "",
          interactable: true,
          autoGround: false,
          groundOffset: 0.1,
          zOffset: 0.0,
          x: null,
          y: null,
          z: null,
          heading: 0.0,
        },
      },
    };
  },

  mounted() {
    this.fetchNpcs();
    this.fetchPlayerPosForAdd();
  },

  methods: {
    async nuiCall(name, payload = {}) {
      const res = await fetch(`https://${GetParentResourceName()}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(payload),
      });

      let json = null;
      try {
        json = await res.json();
      } catch (e) {
        console.error("NUI JSON parse error for", name, e);
      }

      return json || { ok: false, error: "invalid_response" };
    },

    // ====== Load ======
    async fetchNpcs() {
      this.loading = true;
      this.error = null;

      try {
        const res = await this.nuiCall("LCV:ADMIN:Npcs:GetAll");
        if (!res || !res.ok) throw new Error(res.error || "Unbekannter Fehler");
        this.npcs = Array.isArray(res.npcs) ? res.npcs : [];
      } catch (e) {
        console.error("[ADMIN][NPC] Load error:", e);
        this.error = e.message || String(e);
      } finally {
        this.loading = false;
      }
    },

    // ====== Player Position ======
    async fetchPlayerPosForAdd() {
      this.posLoading = true;
      this.addError = null;
      const res = await this.nuiCall("LCV:ADMIN:Npcs:GetPlayerPos", {});
      this.posLoading = false;

      if (!res || !res.ok) {
        this.addError = "Konnte aktuelle Position nicht lesen.";
        return;
      }

      this.addForm.x = res.x;
      this.addForm.y = res.y;
      this.addForm.z = res.z;
      this.addForm.heading = res.heading || 0.0;
    },

    async fetchPlayerPosForEdit() {
      if (!this.editDialog.visible) return;
      this.editDialog.error = null;

      const res = await this.nuiCall("LCV:ADMIN:Npcs:GetPlayerPos", {});
      if (!res || !res.ok) {
        this.editDialog.error = "Konnte aktuelle Position nicht lesen.";
        return;
      }

      this.editDialog.form.x = res.x;
      this.editDialog.form.y = res.y;
      this.editDialog.form.z = res.z;
      this.editDialog.form.heading = res.heading || 0.0;
    },

    // ====== Helpers ======
    yesNo(v) {
      return v ? "Ja" : "Nein";
    },

    // ====== Teleport zum NPC ======
    async teleport(row) {
      await this.nuiCall("LCV:ADMIN:Npcs:Teleport", {
        id: row.id,
        x: row.x,
        y: row.y,
        z: row.z,
      });
    },

    // ====== EDIT ======
    openEdit(row) {
      this.editDialog.visible = true;
      this.editDialog.busy = false;
      this.editDialog.error = null;

      this.editDialog.form = {
        id: row.id,
        name: row.name || "",
        model: row.model || "",
        scenario: row.scenario || "",
        interactionType: row.interactionType || "",
        interactable: !!row.interactable,
        autoGround: !!row.autoGround,
        groundOffset: Number(row.groundOffset) || 0.1,
        zOffset: Number(row.zOffset) || 0.0,
        x: Number(row.x),
        y: Number(row.y),
        z: Number(row.z),
        heading: Number(row.heading) || 0.0,
      };
    },

    cancelEdit() {
      this.editDialog.visible = false;
      this.editDialog.busy = false;
      this.editDialog.error = null;
      this.editDialog.form = {
        id: null,
        name: "",
        model: "",
        scenario: "",
        interactionType: "",
        interactable: true,
        autoGround: false,
        groundOffset: 0.1,
        zOffset: 0.0,
        x: null,
        y: null,
        z: null,
        heading: 0.0,
      };
    },

    async submitEdit() {
      const f = this.editDialog.form;
      this.editDialog.error = null;

      if (!f.id) {
        this.editDialog.error = "Ungültige ID.";
        return;
      }
      if (!f.name.trim()) {
        this.editDialog.error = "Name ist erforderlich.";
        return;
      }
      if (!f.model.trim()) {
        this.editDialog.error = "Model ist erforderlich.";
        return;
      }
      if (
        f.x === null ||
        f.y === null ||
        f.z === null ||
        isNaN(f.x) ||
        isNaN(f.y) ||
        isNaN(f.z)
      ) {
        this.editDialog.error =
          "Ungültige Position. Bitte Koordinaten prüfen oder Position übernehmen.";
        return;
      }

      const payload = {
        id: f.id,
        name: f.name.trim(),
        model: f.model.trim(),
        scenario: (f.scenario || "").trim() || null,
        interactionType: (f.interactionType || "").trim() || null,
        interactable: !!f.interactable,
        autoGround: !!f.autoGround,
        groundOffset: Number(f.groundOffset) || 0.1,
        zOffset: Number(f.zOffset) || 0.0,
        x: Number(f.x),
        y: Number(f.y),
        z: Number(f.z),
        heading: Number(f.heading) || 0.0,
      };

      this.editDialog.busy = true;
      const res = await this.nuiCall("LCV:ADMIN:Npcs:Update", payload);
      this.editDialog.busy = false;

      if (!res || !res.ok) {
        this.editDialog.error =
          "Speichern fehlgeschlagen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      await this.fetchNpcs();
      this.cancelEdit();
    },

    // ====== DELETE ======
    openDeleteConfirm(row) {
      this.deleteConfirm.visible = true;
      this.deleteConfirm.row = row;
      this.deleteConfirm.busy = false;
      this.deleteConfirm.error = null;
    },

    cancelDelete() {
      this.deleteConfirm.visible = false;
      this.deleteConfirm.row = null;
      this.deleteConfirm.busy = false;
      this.deleteConfirm.error = null;
    },

    async confirmDelete() {
      if (!this.deleteConfirm.row || this.deleteConfirm.busy) return;

      this.deleteConfirm.busy = true;
      this.deleteConfirm.error = null;

      const row = this.deleteConfirm.row;
      const res = await this.nuiCall("LCV:ADMIN:Npcs:Delete", { id: row.id });

      this.deleteConfirm.busy = false;

      if (!res || !res.ok) {
        this.deleteConfirm.error =
          "Löschen fehlgeschlagen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      this.npcs = this.npcs.filter((n) => n.id !== row.id);
      this.cancelDelete();
    },

    // ====== ADD ======
    async submitAdd() {
      this.addError = null;

      if (!this.addForm.name.trim()) {
        this.addError = "Name ist erforderlich.";
        return;
      }
      if (!this.addForm.model.trim()) {
        this.addError = "Model ist erforderlich.";
        return;
      }
      if (
        this.addForm.x === null ||
        this.addForm.y === null ||
        this.addForm.z === null
      ) {
        this.addError =
          "Keine Position gesetzt. Bitte 'Position übernehmen' klicken.";
        return;
      }

      const payload = {
        name: this.addForm.name.trim(),
        model: this.addForm.model.trim(),
        scenario: (this.addForm.scenario || "").trim() || null,
        interactionType: (this.addForm.interactionType || "").trim() || null,
        interactable: !!this.addForm.interactable,
        autoGround: !!this.addForm.autoGround,
        groundOffset: Number(this.addForm.groundOffset) || 0.1,
        zOffset: Number(this.addForm.zOffset) || 0.0,
        x: this.addForm.x,
        y: this.addForm.y,
        z: this.addForm.z,
        heading: Number(this.addForm.heading) || 0.0,
      };

      const res = await this.nuiCall("LCV:ADMIN:Npcs:Add", payload);

      if (!res || !res.ok) {
        this.addError =
          "Fehler beim Hinzufügen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      this.resetAddForm();
      await this.fetchNpcs();
    },

    resetAddForm() {
      this.addForm.name = "";
      this.addForm.model = "";
      this.addForm.scenario = "";
      this.addForm.interactionType = "";
      this.addForm.interactable = true;
      this.addForm.autoGround = false;
      this.addForm.groundOffset = 0.1;
      this.addForm.zOffset = 0.0;
      // Position + Heading lassen wir stehen, praktisch für mehrere am Spot
    },
  },

  template: `
    <div class="options">
      <div class="interaction-header">
        <h1>NPCs</h1>
        <div class="header-buttons">
          <button class="refresh-btn" @click="fetchNpcs">
            <i class="fa-solid fa-rotate"></i>
            Reload
          </button>
        </div>
      </div>

      <p class="hint">
        Übersicht & Verwaltung aller statischen NPCs.
        Rechts: Teleport · Edit · Delete.
        Unten: neue NPCs mit aktueller Position anlegen.
      </p>

      <div v-if="loading" class="status">Lade NPCs ...</div>
      <div v-else-if="error" class="status error">Fehler: {{ error }}</div>

      <div v-else class="table-wrapper">
        <table v-if="npcs.length" class="table-interactions">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Model</th>
              <th>X</th>
              <th>Y</th>
              <th>Z</th>
              <th>Heading</th>
              <th>Scenario</th>
              <th>Interaction</th>
              <th>Interactable</th>
              <th>AutoGround</th>
              <th>Offsets</th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in npcs" :key="row.id">
              <td>{{ row.id }}</td>
              <td>{{ row.name }}</td>
              <td>{{ row.model }}</td>
              <td>{{ row.x.toFixed(2) }}</td>
              <td>{{ row.y.toFixed(2) }}</td>
              <td>{{ row.z.toFixed(2) }}</td>
              <td>{{ row.heading.toFixed(1) }}</td>
              <td>{{ row.scenario || '-' }}</td>
              <td>{{ row.interactionType || '-' }}</td>
              <td>{{ yesNo(row.interactable) }}</td>
              <td>{{ yesNo(row.autoGround) }}</td>
              <td>g: {{ row.groundOffset }} / z: {{ row.zOffset }}</td>
              <td class="actions">
                <button class="btn-icon" title="Teleport" @click="teleport(row)">
                  <i class="fa-solid fa-location-arrow"></i>
                </button>
                <button class="btn-icon" title="Bearbeiten" @click="openEdit(row)">
                  <i class="fa-solid fa-pen"></i>
                </button>
                <button class="btn-icon danger" title="Löschen" @click="openDeleteConfirm(row)">
                  <i class="fa-solid fa-trash"></i>
                </button>
              </td>
            </tr>
          </tbody>
        </table>

        <div v-if="!npcs.length" class="status">
          Keine NPCs gefunden.
        </div>
      </div>

      <!-- Add-Form -->
      <div class="add-form">
        <h2>Neuen NPC anlegen</h2>

        <div class="add-grid">
          <div class="field">
            <label>Name</label>
            <input v-model="addForm.name" type="text" placeholder="z.B. Officer Hudson" />
          </div>

          <div class="field">
            <label>Model</label>
            <input v-model="addForm.model" type="text" placeholder="z.B. S_M_Y_Cop_01" />
          </div>

          <div class="field">
            <label>Scenario</label>
            <select v-model="addForm.scenario">
              <option v-for="s in scenarioOptions" :key="s.value" :value="s.value">
                {{ s.label }}<span v-if="s.value"> ({{ s.value }})</span>
              </option>
            </select>
          </div>

          <div class="field">
            <label>Interaction-Type</label>
            <input v-model="addForm.interactionType" type="text" placeholder="optional Tag" />
          </div>
        </div>

        <div class="add-grid">
          <div class="field switch-field">
            <label>Interactable</label>
            <div class="switch" :class="{ on: addForm.interactable }" @click="addForm.interactable = !addForm.interactable">
              <div class="knob"></div>
            </div>
          </div>

          <div class="field switch-field">
            <label>AutoGround</label>
            <div class="switch" :class="{ on: addForm.autoGround }" @click="addForm.autoGround = !addForm.autoGround">
              <div class="knob"></div>
            </div>
          </div>

          <div class="field">
            <label>Ground Offset</label>
            <input v-model.number="addForm.groundOffset" type="number" step="0.01" />
          </div>

          <div class="field">
            <label>Z Offset</label>
            <input v-model.number="addForm.zOffset" type="number" step="0.01" />
          </div>
        </div>

        <div class="field">
          <label>Position (X / Y / Z / Heading)</label>
          <div class="pos-row">
            <input type="text" :value="addForm.x !== null ? addForm.x.toFixed(3) : ''" readonly placeholder="X" />
            <input type="text" :value="addForm.y !== null ? addForm.y.toFixed(3) : ''" readonly placeholder="Y" />
            <input type="text" :value="addForm.z !== null ? addForm.z.toFixed(3) : ''" readonly placeholder="Z" />
            <input type="text" :value="addForm.heading.toFixed(1)" readonly placeholder="H" />
            <button class="pos-btn" @click="fetchPlayerPosForAdd" :disabled="posLoading">
              <i class="fa-solid fa-location-crosshairs"></i>
              {{ posLoading ? '...' : 'Position übernehmen' }}
            </button>
          </div>
        </div>

        <div class="add-actions">
          <div class="error" v-if="addError">{{ addError }}</div>
          <button class="add-save-btn" @click="submitAdd">
            <i class="fa-solid fa-save"></i>
            Speichern
          </button>
        </div>
      </div>

      <!-- Delete Modal -->
      <div v-if="deleteConfirm.visible" class="modal-backdrop">
        <div class="modal">
          <h3>NPC löschen?</h3>
          <p v-if="deleteConfirm.row">
            Willst du NPC
            <strong>#{{ deleteConfirm.row.id }} – {{ deleteConfirm.row.name }}</strong>
            wirklich löschen?<br/>
            Dies kann nicht rückgängig gemacht werden.
          </p>

          <div class="modal-error" v-if="deleteConfirm.error">
            {{ deleteConfirm.error }}
          </div>

          <div class="modal-actions">
            <button class="modal-btn" @click="cancelDelete" :disabled="deleteConfirm.busy">
              Abbrechen
            </button>
            <button class="modal-btn danger" @click="confirmDelete" :disabled="deleteConfirm.busy">
              {{ deleteConfirm.busy ? 'Lösche...' : 'Ja, löschen' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Edit Modal -->
      <div v-if="editDialog.visible" class="modal-backdrop">
        <div class="modal">
          <h3>NPC bearbeiten</h3>

          <div class="modal-error" v-if="editDialog.error">
            {{ editDialog.error }}
          </div>

          <div class="add-grid">
            <div class="field">
              <label>Name</label>
              <input v-model="editDialog.form.name" type="text" />
            </div>

            <div class="field">
              <label>Model</label>
              <input v-model="editDialog.form.model" type="text" />
            </div>

            <div class="field">
              <label>Scenario</label>
              <select v-model="editDialog.form.scenario">
                <option v-for="s in scenarioOptions" :key="s.value" :value="s.value">
                  {{ s.label }}<span v-if="s.value"> ({{ s.value }})</span>
                </option>
              </select>
            </div>

            <div class="field">
              <label>Interaction-Type</label>
              <input v-model="editDialog.form.interactionType" type="text" />
            </div>
          </div>

          <div class="add-grid">
            <div class="field switch-field">
              <label>Interactable</label>
              <div class="switch" :class="{ on: editDialog.form.interactable }" @click="editDialog.form.interactable = !editDialog.form.interactable">
                <div class="knob"></div>
              </div>
            </div>

            <div class="field switch-field">
              <label>AutoGround</label>
              <div class="switch" :class="{ on: editDialog.form.autoGround }" @click="editDialog.form.autoGround = !editDialog.form.autoGround">
                <div class="knob"></div>
              </div>
            </div>

            <div class="field">
              <label>Ground Offset</label>
              <input v-model.number="editDialog.form.groundOffset" type="number" step="0.01" />
            </div>

            <div class="field">
              <label>Z Offset</label>
              <input v-model.number="editDialog.form.zOffset" type="number" step="0.01" />
            </div>
          </div>

          <div class="field">
            <label>Position (X / Y / Z / Heading)</label>
            <div class="pos-row">
              <input type="text" v-model="editDialog.form.x" />
              <input type="text" v-model="editDialog.form.y" />
              <input type="text" v-model="editDialog.form.z" />
              <input type="text" v-model="editDialog.form.heading" />
              <button class="pos-btn" @click="fetchPlayerPosForEdit">
                <i class="fa-solid fa-location-crosshairs"></i>
                Aktuelle Pos
              </button>
            </div>
          </div>

          <div class="modal-actions">
            <button class="modal-btn" @click="cancelEdit" :disabled="editDialog.busy">
              Abbrechen
            </button>
            <button class="modal-btn danger" @click="submitEdit" :disabled="editDialog.busy">
              {{ editDialog.busy ? 'Speichere...' : 'Speichern' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
});
