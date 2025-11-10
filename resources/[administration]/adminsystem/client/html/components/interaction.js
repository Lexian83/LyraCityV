Vue.component("tab-interaction", {
  props: ["identity"],

  data() {
    return {
      loading: true,
      error: null,
      interactions: [],

      // Formular: Neue Interaction
      addForm: {
        name: "",
        description: "",
        type: "generic",
        radius: 1.0,
        enabled: true,
        data: "",
        x: null,
        y: null,
        z: null,
      },
      addError: null,
      posLoading: false,

      // Delete-Confirm Modal
      deleteConfirm: {
        visible: false,
        row: null,
        busy: false,
        error: null,
      },

      // Edit-Modal
      editDialog: {
        visible: false,
        busy: false,
        error: null,
        form: {
          id: null,
          name: "",
          description: "",
          type: "generic",
          radius: 1.0,
          enabled: true,
          data: "",
          x: null,
          y: null,
          z: null,
        },
      },
    };
  },

  mounted() {
    this.fetchInteractions();
    this.fetchPlayerPos(); // für Add-Form vorbefüllen
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
    async fetchInteractions() {
      this.loading = true;
      this.error = null;

      try {
        const json = await this.nuiCall("LCV:ADMIN:Interactions:GetAll");

        if (!json || !json.ok) {
          throw new Error(json.error || "Unbekannter Fehler");
        }

        this.interactions = Array.isArray(json.interactions)
          ? json.interactions
          : [];
      } catch (err) {
        console.error("[ADMIN][Interaction] Load error:", err);
        this.error = err.message || String(err);
      } finally {
        this.loading = false;
      }
    },

    // ====== Player Position (für Add & Edit) ======
    async fetchPlayerPos() {
      this.posLoading = true;
      this.addError = null;

      const res = await this.nuiCall("LCV:ADMIN:Interactions:GetPlayerPos", {});
      this.posLoading = false;

      if (!res || !res.ok) {
        this.addError = "Konnte aktuelle Position nicht lesen.";
        return;
      }

      this.addForm.x = res.x;
      this.addForm.y = res.y;
      this.addForm.z = res.z;
    },

    async fetchPlayerPosForEdit() {
      if (!this.editDialog.visible) return;

      this.editDialog.error = null;
      const res = await this.nuiCall("LCV:ADMIN:Interactions:GetPlayerPos", {});

      if (!res || !res.ok) {
        this.editDialog.error = "Konnte aktuelle Position nicht lesen.";
        return;
      }

      this.editDialog.form.x = res.x;
      this.editDialog.form.y = res.y;
      this.editDialog.form.z = res.z;
    },

    // ====== Helpers ======
    formatEnabled(v) {
      return v ? "Ja" : "Nein";
    },

    formatData(data) {
      if (!data) return "-";
      if (typeof data === "string") return data;
      try {
        return JSON.stringify(data);
      } catch (e) {
        return "-";
      }
    },

    // ====== Teleport ======
    async teleport(row) {
      await this.nuiCall("LCV:ADMIN:Interactions:Teleport", {
        id: row.id,
        x: row.x,
        y: row.y,
        z: row.z,
      });
    },

    // ====== EDIT: NUI Modal ======

    openEdit(row) {
      // data normalisieren
      let dataString = "";
      if (typeof row.data === "string") {
        dataString = row.data;
      } else if (row.data && typeof row.data === "object") {
        try {
          dataString = JSON.stringify(row.data, null, 2);
        } catch (e) {
          dataString = "";
        }
      }

      this.editDialog.visible = true;
      this.editDialog.busy = false;
      this.editDialog.error = null;
      this.editDialog.form = {
        id: row.id,
        name: row.name || "",
        description: row.description || "",
        type: row.type || "generic",
        radius: Number(row.radius) || 1.0,
        enabled: !!row.enabled,
        data: dataString,
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
        description: "",
        type: "generic",
        radius: 1.0,
        enabled: true,
        data: "",
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
        description: f.description.trim(),
        type: f.type || "generic",
        x: Number(f.x),
        y: Number(f.y),
        z: Number(f.z),
        radius: Number(f.radius) || 1.0,
        enabled: !!f.enabled,
        data: f.data.trim(),
      };

      this.editDialog.busy = true;

      const res = await this.nuiCall("LCV:ADMIN:Interactions:Update", payload);

      this.editDialog.busy = false;

      if (!res || !res.ok) {
        this.editDialog.error =
          "Speichern fehlgeschlagen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      // Liste neu laden (server triggert reloadPoints für den Manager)
      await this.fetchInteractions();
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
      const res = await this.nuiCall("LCV:ADMIN:Interactions:Delete", {
        id: row.id,
      });

      this.deleteConfirm.busy = false;

      if (!res || !res.ok) {
        this.deleteConfirm.error =
          "Löschen fehlgeschlagen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      this.interactions = this.interactions.filter((r) => r.id !== row.id);
      this.cancelDelete();
    },

    // ====== ADD ======

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
        description: this.addForm.description.trim(),
        type: this.addForm.type || "generic",
        x: this.addForm.x,
        y: this.addForm.y,
        z: this.addForm.z,
        radius: Number(this.addForm.radius) || 1.0,
        enabled: !!this.addForm.enabled,
        data: this.addForm.data.trim(),
      };

      const res = await this.nuiCall("LCV:ADMIN:Interactions:Add", payload);

      if (!res || !res.ok) {
        this.addError =
          "Fehler beim Hinzufügen: " +
          (res && res.error ? res.error : "Unbekannter Fehler");
        return;
      }

      this.resetAddForm();
      this.fetchInteractions();
    },

    resetAddForm() {
      this.addForm.name = "";
      this.addForm.description = "";
      this.addForm.type = "generic";
      this.addForm.radius = 1.0;
      this.addForm.enabled = true;
      this.addForm.data = "";
      // Position lassen wir stehen (praktisch für mehrere am gleichen Ort)
    },
  },

  template: `
    <div class="options">
      <div class="interaction-header">
        <h1>Interaction Points</h1>
        <div class="header-buttons">
          <button class="refresh-btn" @click="fetchInteractions">
            <i class="fa-solid fa-rotate"></i>
            Reload
          </button>
        </div>
      </div>

      <p class="hint">
        Übersicht & Verwaltung aller Interaction-Points.
        Rechts: Teleport · Edit · Delete.
        Unten: neue Punkte mit aktueller Position anlegen.
      </p>

      <div v-if="loading" class="status">Lade Interaktionen ...</div>
      <div v-else-if="error" class="status error">Fehler: {{ error }}</div>

      <div v-else class="table-wrapper">
        <table v-if="interactions.length" class="table-interactions">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Beschreibung</th>
              <th>Typ</th>
              <th>X</th>
              <th>Y</th>
              <th>Z</th>
              <th>Radius</th>
              <th>Aktiv</th>
              <th>Data</th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in interactions" :key="row.id">
              <td>{{ row.id }}</td>
              <td>{{ row.name }}</td>
              <td>{{ row.description || '-' }}</td>
              <td>{{ row.type }}</td>
              <td>{{ row.x }}</td>
              <td>{{ row.y }}</td>
              <td>{{ row.z }}</td>
              <td>{{ row.radius }}</td>
              <td>{{ formatEnabled(row.enabled) }}</td>
              <td class="data-cell">{{ formatData(row.data) }}</td>
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

        <div v-if="!interactions.length" class="status">
          Keine Interaktionen gefunden.
        </div>
      </div>

      <!-- Formular: Neue Interaction -->
      <div class="add-form">
        <h2>Neue Interaction anlegen</h2>

        <div class="add-grid">
          <div class="field">
            <label>Name</label>
            <input v-model="addForm.name" type="text" placeholder="z.B. MRPD Frontdesk PC" />
          </div>

          <div class="field">
            <label>Typ</label>
            <select v-model="addForm.type">
              <option value="generic">generic</option>
              <option value="pc">pc</option>
              <option value="atm">atm</option>
              <option value="job_terminal">job_terminal</option>
              <option value="custom">custom</option>
            </select>
          </div>

          <div class="field">
            <label>Radius</label>
            <input v-model.number="addForm.radius" type="number" step="0.1" min="0" />
          </div>

          <div class="field switch-field">
            <label>Aktiv</label>
            <div class="switch" :class="{ on: addForm.enabled }" @click="addForm.enabled = !addForm.enabled">
              <div class="knob"></div>
            </div>
          </div>
        </div>

        <div class="add-grid">
          <div class="field">
            <label>Position (X / Y / Z)</label>
            <div class="pos-row">
              <input type="text" :value="addForm.x !== null ? addForm.x.toFixed(3) : ''" readonly placeholder="X" />
              <input type="text" :value="addForm.y !== null ? addForm.y.toFixed(3) : ''" readonly placeholder="Y" />
              <input type="text" :value="addForm.z !== null ? addForm.z.toFixed(3) : ''" readonly placeholder="Z" />
              <button class="pos-btn" @click="fetchPlayerPos" :disabled="posLoading">
                <i class="fa-solid fa-location-crosshairs"></i>
                {{ posLoading ? '...' : 'Position übernehmen' }}
              </button>
            </div>
          </div>
        </div>

        <div class="field">
          <label>Beschreibung</label>
          <textarea v-model="addForm.description" rows="2" placeholder="Interne Beschreibung..."></textarea>
        </div>

        <div class="field">
          <label>Data (JSON / Zusatzinfos)</label>
          <textarea v-model="addForm.data" rows="3" placeholder='z.B. {"department":"LSPD"}'></textarea>
        </div>

        <div class="add-actions">
          <div class="error" v-if="addError">{{ addError }}</div>
          <button class="add-save-btn" @click="submitAdd">
            <i class="fa-solid fa-save"></i>
            Speichern
          </button>
        </div>
      </div>

      <!-- Delete Confirm Modal -->
      <div v-if="deleteConfirm.visible" class="modal-backdrop">
        <div class="modal">
          <h3>Eintrag löschen?</h3>
          <p v-if="deleteConfirm.row">
            Willst du Interaction
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
          <h3>Interaction bearbeiten</h3>

          <div class="modal-error" v-if="editDialog.error">
            {{ editDialog.error }}
          </div>

          <div class="add-grid">
            <div class="field">
              <label>Name</label>
              <input v-model="editDialog.form.name" type="text" />
            </div>

            <div class="field">
              <label>Typ</label>
              <select v-model="editDialog.form.type">
                <option value="generic">generic</option>
                <option value="pc">pc</option>
                <option value="atm">atm</option>
                <option value="job_terminal">job_terminal</option>
                <option value="custom">custom</option>
              </select>
            </div>

            <div class="field">
              <label>Radius</label>
              <input v-model.number="editDialog.form.radius" type="number" step="0.1" min="0" />
            </div>

            <div class="field switch-field">
              <label>Aktiv</label>
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

          <div class="field">
            <label>Beschreibung</label>
            <textarea v-model="editDialog.form.description" rows="2"></textarea>
          </div>

          <div class="field">
            <label>Data (JSON / Zusatzinfos)</label>
            <textarea v-model="editDialog.form.data" rows="3"></textarea>
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
