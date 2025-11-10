// Sichtbarkeits-Optionen (visiblefor)
const BLIP_VISIBLEFOR = [
  { value: 0, label: "Allgemein (alle)" },
  { value: 1, label: "Crime" },
  { value: 2, label: "LSPD" },
  { value: 3, label: "EMS" },
  { value: 4, label: "Government" },
];

// Ein paar sinnvolle Standard-Blip-Sprites (erweiterbar)
const BLIP_SPRITES = [
  { value: 1, label: "1 - Standard" },
  { value: 526, label: "526 - Polizei" },
  { value: 61, label: "61 - Krankenhaus" },
  { value: 446, label: "446 - Werkstatt" },
  { value: 73, label: "73 - Kleidung" },
  { value: 357, label: "357 - Garage" },
  { value: 52, label: "52 - Shop" },
  { value: 140, label: "140 - Weed" },
  { value: 351, label: "351 - Koffer" },
  { value: 188, label: "188 - Handschellen" },
  { value: 198, label: "198 - Taxi" },
  { value: 354, label: "354 - Blitz" },
  { value: 361, label: "361 - Benzinkanister" },
  { value: 51, label: "51 - Pille" },
  { value: 769, label: "769 - Blitz im Dreieck" },
  { value: 499, label: "499 - Laborflasche" },
  { value: 459, label: "459 - Wlan" },
];

// GTA-typische Blip-Farben (kannst du jederzeit erweitern)
const BLIP_COLORS = [
  { value: 0, label: "0 - Weiß" },
  { value: 1, label: "1 - Rot" },
  { value: 2, label: "2 - Grün" },
  { value: 3, label: "3 - Blau" },
  { value: 5, label: "5 - Gelb" },
  { value: 25, label: "25 - Polizei Blau" },
  { value: 46, label: "46 - Shop Grün" },
];

Vue.component("tab-blips", {
  props: ["identity"],

  data() {
    return {
      loading: true,
      error: null,
      blips: [],

      spriteOptions: BLIP_SPRITES,
      colorOptions: BLIP_COLORS,
      visibleForOptions: BLIP_VISIBLEFOR,

      // Add-Form
      addForm: {
        name: "",
        sprite: 1,
        color: 0,
        scale: 1.0,
        visiblefor: 0,
        category: "",
        shortRange: true,
        enabled: true,
        x: null,
        y: null,
        z: null,
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
          sprite: 1,
          color: 0,
          scale: 1.0,
          visiblefor: 0,
          category: "",
          shortRange: true,
          enabled: true,
          x: null,
          y: null,
          z: null,
        },
      },
    };
  },

  mounted() {
    this.fetchBlips();
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

    yesNo(v) {
      return v ? "Ja" : "Nein";
    },

    formatVisibleFor(v) {
      const opt = this.visibleForOptions.find((o) => o.value === Number(v));
      return opt ? opt.label : v;
    },

    getSpriteLabel(v) {
      const opt = this.spriteOptions.find((o) => o.value === Number(v));
      return opt ? opt.label : v;
    },

    getColorLabel(v) {
      const opt = this.colorOptions.find((o) => o.value === Number(v));
      return opt ? opt.label : v;
    },

    // ===== Load =====
    async fetchBlips() {
      this.loading = true;
      this.error = null;
      try {
        const res = await this.nuiCall("LCV:ADMIN:Blips:GetAll");
        if (!res || !res.ok) throw new Error(res.error || "Unbekannter Fehler");
        this.blips = Array.isArray(res.blips) ? res.blips : [];
      } catch (e) {
        console.error("[ADMIN][BLIP] Load error:", e);
        this.error = e.message || String(e);
      } finally {
        this.loading = false;
      }
    },

    // ===== Player Pos (Add) =====
    async fetchPlayerPosForAdd() {
      this.posLoading = true;
      this.addError = null;

      const res = await this.nuiCall("LCV:ADMIN:Blips:GetPlayerPos", {});
      this.posLoading = false;

      if (!res || !res.ok) {
        this.addError = "Konnte aktuelle Position nicht lesen.";
        return;
      }

      this.addForm.x = res.x;
      this.addForm.y = res.y;
      this.addForm.z = res.z;
    },

    // ===== Player Pos (Edit) =====
    async fetchPlayerPosForEdit() {
      if (!this.editDialog.visible) return;
      this.editDialog.error = null;

      const res = await this.nuiCall("LCV:ADMIN:Blips:GetPlayerPos", {});
      if (!res || !res.ok) {
        this.editDialog.error = "Konnte aktuelle Position nicht lesen.";
        return;
      }

      this.editDialog.form.x = res.x;
      this.editDialog.form.y = res.y;
      this.editDialog.form.z = res.z;
    },

    // ===== Teleport =====
    async teleport(row) {
      await this.nuiCall("LCV:ADMIN:Blips:Teleport", {
        id: row.id,
        x: row.x,
        y: row.y,
        z: row.z,
      });
    },

    // ===== EDIT =====
    openEdit(row) {
      this.editDialog.visible = true;
      this.editDialog.busy = false;
      this.editDialog.error = null;

      this.editDialog.form = {
        id: row.id,
        name: row.name || "",
        sprite: Number(row.sprite) || 1,
        color: Number(row.color) || 0,
        scale: Number(row.scale) || 1.0,
        visiblefor: Number(row.visiblefor) || 0,
        category: row.category || "",
        shortRange: !!row.shortRange,
        enabled: !!row.enabled,
        x: Number(row.x),
        y: Number(row.y),
        z: Number(row.z),
      };
    },

    cancelEdit() {
      this.editDialog.visible = false;
      this.editDialog.busy = false;
      this.editDialog.error = null;
      this.editDialog.form = {
        id: null,
        name: "",
        sprite: 1,
        color: 0,
        scale: 1.0,
        visiblefor: 0,
        category: "",
        shortRange: true,
        enabled: true,
        x: null,
        y: null,
        z: null,
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
        x: Number(f.x),
        y: Number(f.y),
        z: Number(f.z),
        sprite: Number(f.sprite) || 1,
        color: Number(f.color) || 0,
        scale: Number(f.scale) || 1.0,
        visiblefor: Number(f.visiblefor) || 0,
        category: (f.category || "").trim() || null,
        shortRange: !!f.shortRange,
        enabled: !!f.enabled,
        display: 4,
      };

      this.editDialog.busy = true;
      const res = await this.nuiCall("LCV:ADMIN:Blips:Update", payload);
      this.editDialog.busy = false;

      if (!res || !res.ok) {
        this.editDialog.error =
          "Speichern fehlgeschlagen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      await this.fetchBlips();
      this.cancelEdit();
    },

    // ===== DELETE =====
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
      const res = await this.nuiCall("LCV:ADMIN:Blips:Delete", { id: row.id });

      this.deleteConfirm.busy = false;

      if (!res || !res.ok) {
        this.deleteConfirm.error =
          "Löschen fehlgeschlagen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      this.blips = this.blips.filter((b) => b.id !== row.id);
      this.cancelDelete();
    },

    // ===== ADD =====
    async submitAdd() {
      this.addError = null;

      if (!this.addForm.name.trim()) {
        this.addError = "Name ist erforderlich.";
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
        x: Number(this.addForm.x),
        y: Number(this.addForm.y),
        z: Number(this.addForm.z),
        sprite: Number(this.addForm.sprite) || 1,
        color: Number(this.addForm.color) || 0,
        scale: Number(this.addForm.scale) || 1.0,
        visiblefor: Number(this.addForm.visiblefor) || 0,
        category: (this.addForm.category || "").trim() || null,
        shortRange: !!this.addForm.shortRange,
        enabled: !!this.addForm.enabled,
        display: 4,
      };

      const res = await this.nuiCall("LCV:ADMIN:Blips:Add", payload);

      if (!res || !res.ok) {
        this.addError =
          "Fehler beim Hinzufügen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      this.resetAddForm(false);
      await this.fetchBlips();
    },

    resetAddForm(keepPos = true) {
      const old = { x: this.addForm.x, y: this.addForm.y, z: this.addForm.z };
      this.addForm.name = "";
      this.addForm.sprite = 1;
      this.addForm.color = 0;
      this.addForm.scale = 1.0;
      this.addForm.visiblefor = 0;
      this.addForm.category = "";
      this.addForm.shortRange = true;
      this.addForm.enabled = true;

      if (!keepPos) {
        this.addForm.x = null;
        this.addForm.y = null;
        this.addForm.z = null;
      } else {
        this.addForm.x = old.x;
        this.addForm.y = old.y;
        this.addForm.z = old.z;
      }
    },
  },

  template: `
    <div class="options">
      <div class="interaction-header">
        <h1>Blips</h1>
        <div class="header-buttons">
          <button class="refresh-btn" @click="fetchBlips">
            <i class="fa-solid fa-rotate"></i>
            Reload
          </button>
        </div>
      </div>

      <p class="hint">
        Übersicht & Verwaltung aller Datenbank-Blips.
        Rechts: Teleport · Edit · Delete.
        Unten: neue Blips mit aktueller Position anlegen.
      </p>

      <div v-if="loading" class="status">Lade Blips ...</div>
      <div v-else-if="error" class="status error">Fehler: {{ error }}</div>

      <div v-else class="table-wrapper">
        <table v-if="blips.length" class="table-interactions">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Sprite</th>
              <th>Farbe</th>
              <th>Scale</th>
              <th>VisibleFor</th>
              <th>Short</th>
              <th>Enabled</th>
              <th>X</th>
              <th>Y</th>
              <th>Z</th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in blips" :key="row.id">
              <td>{{ row.id }}</td>
              <td>{{ row.name }}</td>
              <td>{{ getSpriteLabel(row.sprite) }}</td>
              <td>{{ getColorLabel(row.color) }}</td>
              <td>{{ Number(row.scale).toFixed(2) }}</td>
              <td>{{ formatVisibleFor(row.visiblefor) }}</td>
              <td>{{ yesNo(row.shortRange) }}</td>
              <td>{{ yesNo(row.enabled) }}</td>
              <td>{{ Number(row.x).toFixed(2) }}</td>
              <td>{{ Number(row.y).toFixed(2) }}</td>
              <td>{{ Number(row.z).toFixed(2) }}</td>
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

        <div v-if="!blips.length" class="status">
          Keine Blips gefunden.
        </div>
      </div>

      <!-- Add-Form -->
      <div class="add-form">
        <h2>Neuen Blip anlegen</h2>

        <div class="add-grid">
          <div class="field">
            <label>Name</label>
            <input v-model="addForm.name" type="text" placeholder="z.B. Police HQ" />
          </div>

          <div class="field">
            <label>Sprite</label>
            <select v-model.number="addForm.sprite">
              <option v-for="s in spriteOptions" :key="s.value" :value="s.value">
                {{ s.label }}
              </option>
            </select>
          </div>

          <div class="field">
            <label>Farbe</label>
            <select v-model.number="addForm.color">
              <option v-for="c in colorOptions" :key="c.value" :value="c.value">
                {{ c.label }}
              </option>
            </select>
          </div>

          <div class="field">
            <label>VisibleFor</label>
            <select v-model.number="addForm.visiblefor">
              <option v-for="v in visibleForOptions" :key="v.value" :value="v.value">
                {{ v.label }}
              </option>
            </select>
          </div>
        </div>

        <div class="add-grid">
          <div class="field">
            <label>Scale</label>
            <input v-model.number="addForm.scale" type="number" step="0.05" min="0.1" />
          </div>

          <div class="field">
            <label>Category (optional)</label>
            <input v-model="addForm.category" type="text" placeholder="z.B. job_police" />
          </div>

          <div class="field switch-field">
            <label>Short-Range</label>
            <div class="switch" :class="{ on: addForm.shortRange }" @click="addForm.shortRange = !addForm.shortRange">
              <div class="knob"></div>
            </div>
          </div>

          <div class="field switch-field">
            <label>Enabled</label>
            <div class="switch" :class="{ on: addForm.enabled }" @click="addForm.enabled = !addForm.enabled">
              <div class="knob"></div>
            </div>
          </div>
        </div>

        <div class="field">
          <label>Position (X / Y / Z)</label>
          <div class="pos-row">
            <input type="text" :value="addForm.x !== null ? addForm.x.toFixed(3) : ''" readonly placeholder="X" />
            <input type="text" :value="addForm.y !== null ? addForm.y.toFixed(3) : ''" readonly placeholder="Y" />
            <input type="text" :value="addForm.z !== null ? addForm.z.toFixed(3) : ''" readonly placeholder="Z" />
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
          <h3>Blip löschen?</h3>
          <p v-if="deleteConfirm.row">
            Willst du Blip
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
          <h3>Blip bearbeiten</h3>

          <div class="modal-error" v-if="editDialog.error">
            {{ editDialog.error }}
          </div>

          <div class="add-grid">
            <div class="field">
              <label>Name</label>
              <input v-model="editDialog.form.name" type="text" />
            </div>

            <div class="field">
              <label>Sprite</label>
              <select v-model.number="editDialog.form.sprite">
                <option v-for="s in spriteOptions" :key="s.value" :value="s.value">
                  {{ s.label }}
                </option>
              </select>
            </div>

            <div class="field">
              <label>Farbe</label>
              <select v-model.number="editDialog.form.color">
                <option v-for="c in colorOptions" :key="c.value" :value="c.value">
                  {{ c.label }}
                </option>
              </select>
            </div>

            <div class="field">
              <label>VisibleFor</label>
              <select v-model.number="editDialog.form.visiblefor">
                <option v-for="v in visibleForOptions" :key="v.value" :value="v.value">
                  {{ v.label }}
                </option>
              </select>
            </div>
          </div>

          <div class="add-grid">
            <div class="field">
              <label>Scale</label>
              <input v-model.number="editDialog.form.scale" type="number" step="0.05" min="0.1" />
            </div>

            <div class="field">
              <label>Category</label>
              <input v-model="editDialog.form.category" type="text" />
            </div>

            <div class="field switch-field">
              <label>Short-Range</label>
              <div class="switch" :class="{ on: editDialog.form.shortRange }" @click="editDialog.form.shortRange = !editDialog.form.shortRange">
                <div class="knob"></div>
              </div>
            </div>

            <div class="field switch-field">
              <label>Enabled</label>
              <div class="switch" :class="{ on: editDialog.form.enabled }" @click="editDialog.form.enabled = !editDialog.form.enabled">
                <div class="knob"></div>
              </div>
            </div>
          </div>

          <div class="field">
            <label>Position (X / Y / Z)</label>
            <div class="pos-row">
              <input type="text" v-model="editDialog.form.x" />
              <input type="text" v-model="editDialog.form.y" />
              <input type="text" v-model="editDialog.form.z" />
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
