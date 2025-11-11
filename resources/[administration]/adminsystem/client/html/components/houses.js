Vue.component("tab-houses", {
  props: ["identity"],
  data() {
    return {
      loading: true,
      error: null,
      houses: [],
      ipls: [],

      sortField: "id",
      sortDir: "asc",

      // Add/Edit
      addMode: false,
      addForm: {
        name: "",
        ownerid: "",
        price: 0,
        rent: 0,
        ipl: "",
        entry_x: null,
        entry_y: null,
        entry_z: null,
        garage_trigger_x: null,
        garage_trigger_y: null,
        garage_trigger_z: null,
        garage_x: null,
        garage_y: null,
        garage_z: null,
        radius: 0.5,
      },

      addError: null,

      editDialog: {
        visible: false,
        busy: false,
        error: null,
        form: {},
      },

      deleteConfirm: {
        visible: false,
        row: null,
        busy: false,
        error: null,
      },
    };
  },

  mounted() {
    this.reloadAll();
  },

  methods: {
    async nuiCall(name, payload = {}) {
      const res = await fetch(`https://${GetParentResourceName()}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(payload),
      });
      try {
        return await res.json();
      } catch (e) {
        console.error("NUI JSON error for", name, e);
        return { ok: false, error: "invalid_response" };
      }
    },

    async reloadAll() {
      this.loading = true;
      this.error = null;
      try {
        const [hRes, iplRes] = await Promise.all([
          this.nuiCall("LCV:ADMIN:Houses:GetAll"),
          this.nuiCall("LCV:ADMIN:HousesIPL:GetAll"),
        ]);

        if (!hRes.ok) throw new Error(hRes.error || "Fehler Houses");
        if (!iplRes.ok) throw new Error(iplRes.error || "Fehler Houses_IPL");

        this.houses = Array.isArray(hRes.houses) ? hRes.houses : [];
        this.ipls = Array.isArray(iplRes.ipls) ? iplRes.ipls : [];
      } catch (e) {
        this.error = e.message || String(e);
      } finally {
        this.loading = false;
      }
    },

    // ===== SORTING =====
    setSort(field) {
      if (this.sortField === field) {
        this.sortDir = this.sortDir === "asc" ? "desc" : "asc";
      } else {
        this.sortField = field;
        this.sortDir = "asc";
      }
    },
    sortIndicator(field) {
      if (this.sortField !== field) return "";
      return this.sortDir === "asc" ? "▲" : "▼";
    },
    sortedHouses() {
      const list = [...this.houses];
      const f = this.sortField;
      const dir = this.sortDir === "asc" ? 1 : -1;

      return list.sort((a, b) => {
        let av = a[f];
        let bv = b[f];

        if (f === "ownerid") {
          av = Number(av) || 0;
          bv = Number(bv) || 0;
        }

        if (av === bv) return 0;
        return av > bv ? dir : -dir;
      });
    },

    // ===== STATUS TEXT =====
    formatStatus(h) {
      if (!h.ownerid || h.ownerid === 0) return "frei";
      if (h.ownerid && !h.rent_start) return "verkauft";
      return "vermietet";
    },

    formatIPL(id) {
      const ipl = this.ipls.find((i) => i.id === id);
      return ipl ? `${ipl.id} - ${ipl.ipl_name}` : "-";
    },

    // ===== PLAYER POS HELPER =====
    async fillFromPlayer(targetFields) {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetPlayerPos");
      if (!res.ok) {
        this.addError = "Konnte Position nicht lesen.";
        return;
      }
      targetFields.x = res.x;
      targetFields.y = res.y;
      targetFields.z = res.z;
    },

    // ===== ADD MODE / PLACEMENT MODE =====
    enterAddMode() {
      this.addMode = true;
      this.addError = null;
      this.addForm = {
        name: "",
        ownerid: "",
        price: 0,
        rent: 0,
        ipl: "",
        entry_x: null,
        entry_y: null,
        entry_z: null,
        garage_trigger_x: null,
        garage_trigger_y: null,
        garage_trigger_z: null,
        garage_x: null,
        garage_y: null,
        garage_z: null,
        radius: 0.5,
      };

      // 1/3 View + Steuerung freigeben
      this.nuiCall("LCV:ADMIN:UI:SetPlacementMode", { enabled: true });
    },

    cancelAdd() {
      this.addMode = false;
      this.addError = null;
      this.nuiCall("LCV:ADMIN:UI:SetPlacementMode", { enabled: false });
    },

    // ===== ADD: SET BUTTONS =====
    async setEntryFromPlayer() {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetPlayerPos");
      if (res.ok) {
        this.addForm.entry_x = res.x;
        this.addForm.entry_y = res.y;
        this.addForm.entry_z = res.z;
      }
    },
    async setGarageTriggerFromPlayer() {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetPlayerPos");
      if (res.ok) {
        this.addForm.garage_trigger_x = res.x;
        this.addForm.garage_trigger_y = res.y;
        this.addForm.garage_trigger_z = res.z;
      }
    },
    async setGarageSpawnFromPlayer() {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetPlayerPos");
      if (res.ok) {
        this.addForm.garage_x = res.x;
        this.addForm.garage_y = res.y;
        this.addForm.garage_z = res.z;
      }
    },

    async submitAdd() {
      this.addError = null;

      if (!this.addForm.name.trim()) {
        this.addError = "Name ist erforderlich.";
        return;
      }
      if (
        this.addForm.entry_x === null ||
        this.addForm.entry_y === null ||
        this.addForm.entry_z === null
      ) {
        this.addError = "Eingang ist erforderlich (Eingang setzen).";
        return;
      }

      const payload = {
        name: this.addForm.name.trim(),
        ownerid: this.addForm.ownerid ? Number(this.addForm.ownerid) : 0,
        price: Number(this.addForm.price) || 0,
        rent: Number(this.addForm.rent) || 0,
        ipl: this.addForm.ipl ? Number(this.addForm.ipl) : null,
        entry_x: this.addForm.entry_x,
        entry_y: this.addForm.entry_y,
        entry_z: this.addForm.entry_z,
        garage_trigger_x: this.addForm.garage_trigger_x,
        garage_trigger_y: this.addForm.garage_trigger_y,
        garage_trigger_z: this.addForm.garage_trigger_z,
        garage_x: this.addForm.garage_x,
        garage_y: this.addForm.garage_y,
        garage_z: this.addForm.garage_z,
        radius: Number(this.addForm.radius) || 0.5,
      };

      const res = await this.nuiCall("LCV:ADMIN:Houses:Add", payload);
      if (!res.ok) {
        this.addError =
          "Speichern fehlgeschlagen: " + (res.error || "Unbekannter Fehler");
        return;
      }

      this.addMode = false;
      this.nuiCall("LCV:ADMIN:UI:SetPlacementMode", { enabled: false });
      await this.reloadAll();
    },

    // ===== EDIT =====
    openEdit(row) {
      this.editDialog.visible = true;
      this.editDialog.busy = false;
      this.editDialog.error = null;
      this.editDialog.form = {
        id: row.id,
        name: row.name || "",
        ownerid: row.ownerid || "",
        price: row.price || 0,
        rent: row.rent || 0,
        ipl: row.ipl || "",
        entry_x: row.entry_x,
        entry_y: row.entry_y,
        entry_z: row.entry_z,
        garage_trigger_x: row.garage_trigger_x,
        garage_trigger_y: row.garage_trigger_y,
        garage_trigger_z: row.garage_trigger_z,
        garage_x: row.garage_x,
        garage_y: row.garage_y,
        garage_z: row.garage_z,
        radius: row.interaction_radius || 0.5,
      };

      // Edit = weiterhin Fullscreen (Placement Mode nur bei Add)
    },

    async setEditEntryFromPlayer() {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetPlayerPos");
      if (res.ok) {
        this.editDialog.form.entry_x = res.x;
        this.editDialog.form.entry_y = res.y;
        this.editDialog.form.entry_z = res.z;
      }
    },
    async setEditGarageTriggerFromPlayer() {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetPlayerPos");
      if (res.ok) {
        this.editDialog.form.garage_trigger_x = res.x;
        this.editDialog.form.garage_trigger_y = res.y;
        this.editDialog.form.garage_trigger_z = res.z;
      }
    },
    async setEditGarageSpawnFromPlayer() {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetPlayerPos");
      if (res.ok) {
        this.editDialog.form.garage_x = res.x;
        this.editDialog.form.garage_y = res.y;
        this.editDialog.form.garage_z = res.z;
      }
    },

    async submitEdit() {
      const f = this.editDialog.form;
      this.editDialog.error = null;
      if (!f.name.trim()) {
        this.editDialog.error = "Name ist erforderlich.";
        return;
      }

      const payload = {
        id: f.id,
        name: f.name.trim(),
        ownerid: f.ownerid ? Number(f.ownerid) : 0,
        price: Number(f.price) || 0,
        rent: Number(f.rent) || 0,
        ipl: f.ipl ? Number(f.ipl) : null,
        entry_x: f.entry_x,
        entry_y: f.entry_y,
        entry_z: f.entry_z,
        garage_trigger_x: f.garage_trigger_x,
        garage_trigger_y: f.garage_trigger_y,
        garage_trigger_z: f.garage_trigger_z,
        garage_x: f.garage_x,
        garage_y: f.garage_y,
        garage_z: f.garage_z,
        radius: Number(f.radius) || 0.5,
      };

      this.editDialog.busy = true;
      const res = await this.nuiCall("LCV:ADMIN:Houses:Update", payload);
      this.editDialog.busy = false;

      if (!res.ok) {
        this.editDialog.error =
          "Speichern fehlgeschlagen: " + (res.error || "Unbekannter Fehler");
        return;
      }

      this.editDialog.visible = false;
      await this.reloadAll();
    },

    cancelEdit() {
      this.editDialog.visible = false;
      this.editDialog.busy = false;
      this.editDialog.error = null;
    },

    // ===== DELETE =====
    openDelete(row) {
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

      const res = await this.nuiCall("LCV:ADMIN:Houses:Delete", {
        id: this.deleteConfirm.row.id,
      });

      this.deleteConfirm.busy = false;

      if (!res.ok) {
        this.deleteConfirm.error =
          "Löschen fehlgeschlagen: " + (res.error || "Unbekannter Fehler");
        return;
      }

      this.cancelDelete();
      await this.reloadAll();
    },

    // ===== TELEPORT =====
    async teleportToEntry(h) {
      if (!h.entry_x || !h.entry_y || !h.entry_z) return;
      await this.nuiCall("LCV:ADMIN:Houses:Teleport", {
        id: h.id,
        x: h.entry_x,
        y: h.entry_y,
        z: h.entry_z,
      });
    },
  },

  template: `
    <div class="options">
      <div class="interaction-header">
        <h1>Houses</h1>
        <div class="header-buttons">
          <button class="add-btn" @click="enterAddMode">
            <i class="fa-solid fa-plus"></i> Neues Haus
          </button>
          <button class="refresh-btn" @click="reloadAll">
            <i class="fa-solid fa-rotate"></i> Reload
          </button>
        </div>
      </div>

      <p class="hint">
        Verwaltung aller Häuser. Status: frei / verkauft / vermietet. Teleport führt zum Eingang.
      </p>

      <div v-if="loading" class="status">Lade Häuser ...</div>
      <div v-else-if="error" class="status error">Fehler: {{ error }}</div>

      <div v-else class="table-wrapper">
        <table v-if="houses.length" class="table-interactions">
          <thead>
            <tr>
              <th class="sortable" @click="setSort('id')">
                ID <span class="sort-indicator">{{ sortIndicator('id') }}</span>
              </th>
              <th>Name</th>
              <th class="sortable" @click="setSort('ownerid')">
                Owner <span class="sort-indicator">{{ sortIndicator('ownerid') }}</span>
              </th>
              <th class="sortable" @click="setSort('status')">
                Status <span class="sort-indicator">{{ sortIndicator('status') }}</span>
              </th>
              <th>Preis</th>
              <th>Miete</th>
              <th>IPL</th>
              <th>Entry</th>
              <th>Garage-Trigger</th>
              <th>Garage-Spawn</th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="h in sortedHouses()" :key="h.id">
              <td>{{ h.id }}</td>
              <td>{{ h.name }}</td>
              <td>{{ h.ownerid || '-' }}</td>
              <td>{{ formatStatus(h) }}</td>
              <td>{{ h.price }}</td>
              <td>{{ h.rent || '-' }}</td>
              <td>{{ formatIPL(h.ipl) }}</td>
              <td>{{ h.entry_x.toFixed(2) }}, {{ h.entry_y.toFixed(2) }}, {{ h.entry_z.toFixed(2) }}</td>
              <td>
                <span v-if="h.garage_trigger_x">
                  {{ h.garage_trigger_x.toFixed(2) }},
                  {{ h.garage_trigger_y.toFixed(2) }},
                  {{ h.garage_trigger_z.toFixed(2) }}
                </span>
                <span v-else>-</span>
              </td>
              <td>
                <span v-if="h.garage_x">
                  {{ h.garage_x.toFixed(2) }},
                  {{ h.garage_y.toFixed(2) }},
                  {{ h.garage_z.toFixed(2) }}
                </span>
                <span v-else>-</span>
              </td>
              <td class="actions">
                <button class="btn-icon" title="Teleport" @click="teleportToEntry(h)">
                  <i class="fa-solid fa-location-arrow"></i>
                </button>
                <button class="btn-icon" title="Bearbeiten" @click="openEdit(h)">
                  <i class="fa-solid fa-pen"></i>
                </button>
                <button class="btn-icon danger" title="Löschen" @click="openDelete(h)">
                  <i class="fa-solid fa-trash"></i>
                </button>
              </td>
            </tr>
          </tbody>
        </table>

        <div v-if="!houses.length" class="status">
          Keine Häuser gefunden.
        </div>
      </div>

      <!-- ADD FORM (Placement Mode, 1/3 View) -->
      <div v-if="addMode" class="add-form">
        <h2>Neues Haus erstellen</h2>

        <div class="add-grid">
          <div class="field">
            <label>Name</label>
            <input v-model="addForm.name" type="text" />
          </div>
          <div class="field">
            <label>OwnerID (optional)</label>
            <input v-model="addForm.ownerid" type="number" />
          </div>
          <div class="field">
            <label>Preis</label>
            <input v-model.number="addForm.price" type="number" />
          </div>
          <div class="field">
            <label>Miete</label>
            <input v-model.number="addForm.rent" type="number" />
          </div>
          <div class="field">
  <label>Interaction Radius</label>
  <input v-model.number="addForm.radius" type="number" step="0.1" min="0.1" />
</div>

        </div>

        <div class="add-grid">
          <div class="field">
            <label>IPL</label>
            <select v-model="addForm.ipl">
              <option value="">- kein -</option>
              <option v-for="ipl in ipls" :key="ipl.id" :value="ipl.id">
                {{ ipl.id }} - {{ ipl.ipl_name }}
              </option>
            </select>
          </div>
        </div>

        <div class="field">
          <label>Eingang (Entry X/Y/Z)</label>
          <div class="pos-row">
            <input type="text" :value="addForm.entry_x || ''" placeholder="X" readonly />
            <input type="text" :value="addForm.entry_y || ''" placeholder="Y" readonly />
            <input type="text" :value="addForm.entry_z || ''" placeholder="Z" readonly />
            <button class="pos-btn" @click="setEntryFromPlayer">
              <i class="fa-solid fa-location-crosshairs"></i>Eingang setzen
            </button>
          </div>
        </div>

        <div class="field">
          <label>Garage Trigger</label>
          <div class="pos-row">
            <input type="text" :value="addForm.garage_trigger_x || ''" placeholder="X" readonly />
            <input type="text" :value="addForm.garage_trigger_y || ''" placeholder="Y" readonly />
            <input type="text" :value="addForm.garage_trigger_z || ''" placeholder="Z" readonly />
            <button class="pos-btn" @click="setGarageTriggerFromPlayer">
              <i class="fa-solid fa-location-crosshairs"></i>Garage setzen
            </button>
          </div>
        </div>

        <div class="field">
          <label>Garage Ausparkpunkt</label>
          <div class="pos-row">
            <input type="text" :value="addForm.garage_x || ''" placeholder="X" readonly />
            <input type="text" :value="addForm.garage_y || ''" placeholder="Y" readonly />
            <input type="text" :value="addForm.garage_z || ''" placeholder="Z" readonly />
            <button class="pos-btn" @click="setGarageSpawnFromPlayer">
              <i class="fa-solid fa-location-crosshairs"></i>Ausparkpunkt
            </button>
          </div>
        </div>

        <div class="add-actions">
          <div class="error" v-if="addError">{{ addError }}</div>
          <div>
            <button class="modal-btn" @click="cancelAdd">Abbrechen</button>
            <button class="add-save-btn" @click="submitAdd">
              <i class="fa-solid fa-save"></i>Speichern
            </button>
          </div>
        </div>
      </div>

      <!-- EDIT MODAL -->
      <div v-if="editDialog.visible" class="modal-backdrop">
        <div class="modal">
          <h3>Haus bearbeiten #{{ editDialog.form.id }}</h3>
          <div class="modal-error" v-if="editDialog.error">{{ editDialog.error }}</div>

          <div class="add-grid">
            <div class="field">
              <label>Name</label>
              <input v-model="editDialog.form.name" type="text" />
            </div>
            <div class="field">
              <label>OwnerID</label>
              <input v-model="editDialog.form.ownerid" type="number" />
            </div>
            <div class="field">
              <label>Preis</label>
              <input v-model.number="editDialog.form.price" type="number" />
            </div>
            <div class="field">
              <label>Miete</label>
              <input v-model.number="editDialog.form.rent" type="number" />
            </div>
            <div class="field">
  <label>Interaction Radius</label>
  <input v-model.number="editDialog.form.radius" type="number" step="0.1" min="0.1" />
</div>

          </div>

          <div class="field">
            <label>IPL</label>
            <select v-model="editDialog.form.ipl">
              <option value="">- kein -</option>
              <option v-for="ipl in ipls" :key="ipl.id" :value="ipl.id">
                {{ ipl.id }} - {{ ipl.ipl_name }}
              </option>
            </select>
          </div>

          <div class="field">
            <label>Eingang</label>
            <div class="pos-row">
              <input v-model="editDialog.form.entry_x" />
              <input v-model="editDialog.form.entry_y" />
              <input v-model="editDialog.form.entry_z" />
              <button class="pos-btn" @click="setEditEntryFromPlayer">
                <i class="fa-solid fa-location-crosshairs"></i>Eingang
              </button>
            </div>
          </div>

          <div class="field">
            <label>Garage Trigger</label>
            <div class="pos-row">
              <input v-model="editDialog.form.garage_trigger_x" />
              <input v-model="editDialog.form.garage_trigger_y" />
              <input v-model="editDialog.form.garage_trigger_z" />
              <button class="pos-btn" @click="setEditGarageTriggerFromPlayer">
                <i class="fa-solid fa-location-crosshairs"></i>Trigger
              </button>
            </div>
          </div>

          <div class="field">
            <label>Garage Ausparkpunkt</label>
            <div class="pos-row">
              <input v-model="editDialog.form.garage_x" />
              <input v-model="editDialog.form.garage_y" />
              <input v-model="editDialog.form.garage_z" />
              <button class="pos-btn" @click="setEditGarageSpawnFromPlayer">
                <i class="fa-solid fa-location-crosshairs"></i>Auspark
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

      <!-- DELETE MODAL -->
      <div v-if="deleteConfirm.visible" class="modal-backdrop">
        <div class="modal">
          <h3>Haus löschen?</h3>
          <p v-if="deleteConfirm.row">
            Haus <strong>#{{ deleteConfirm.row.id }} - {{ deleteConfirm.row.name }}</strong> wirklich löschen?
          </p>
          <div class="modal-error" v-if="deleteConfirm.error">
            {{ deleteConfirm.error }}
          </div>
          <div class="modal-actions">
            <button class="modal-btn" @click="cancelDelete" :disabled="deleteConfirm.busy">Abbrechen</button>
            <button class="modal-btn danger" @click="confirmDelete" :disabled="deleteConfirm.busy">
              {{ deleteConfirm.busy ? 'Lösche...' : 'Ja, löschen' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
});
