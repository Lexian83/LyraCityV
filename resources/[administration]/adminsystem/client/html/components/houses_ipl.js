Vue.component("tab-houses_ipl", {
  props: ["identity"],
  data() {
    return {
      loading: true,
      error: null,
      ipls: [],

      addForm: {
        ipl_name: "",
        ipl: "",
        posx: null,
        posy: null,
        posz: null,
        exit_x: null,
        exit_y: null,
        exit_z: null,
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
    // 1/3 View aktivieren, solange Houses_IPL Tab offen
    this.nuiCall("LCV:ADMIN:UI:SetPlacementMode", { enabled: true });
  },
  beforeDestroy() {
    // zurück auf Fullscreen, wenn Tab verlassen wird
    this.nuiCall("LCV:ADMIN:UI:SetPlacementMode", { enabled: false });
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
      const res = await this.nuiCall("LCV:ADMIN:HousesIPL:GetAll");
      this.loading = false;

      if (!res.ok) {
        this.error = res.error || "Fehler beim Laden";
        this.ipls = [];
        return;
      }

      this.ipls = Array.isArray(res.ipls) ? res.ipls : [];
    },

    async setSpawnFromPlayer(target) {
      const res = await this.nuiCall("LCV:ADMIN:HousesIPL:GetPlayerPos");
      if (!res.ok) return;
      target.posx = res.x;
      target.posy = res.y;
      target.posz = res.z;
    },

    async setExitFromPlayer(target) {
      const res = await this.nuiCall("LCV:ADMIN:HousesIPL:GetPlayerPos");
      if (!res.ok) return;
      target.exit_x = res.x;
      target.exit_y = res.y;
      target.exit_z = res.z;
    },

    // ADD
    async submitAdd() {
      this.addError = null;
      if (!this.addForm.ipl_name.trim()) {
        this.addError = "IPL Name ist erforderlich.";
        return;
      }
      const payload = {
        ipl_name: this.addForm.ipl_name.trim(),
        ipl: this.addForm.ipl ? this.addForm.ipl.trim() : "",
        posx: this.addForm.posx,
        posy: this.addForm.posy,
        posz: this.addForm.posz,
        exit_x: this.addForm.exit_x,
        exit_y: this.addForm.exit_y,
        exit_z: this.addForm.exit_z,
      };

      const res = await this.nuiCall("LCV:ADMIN:HousesIPL:Add", payload);
      if (!res.ok) {
        this.addError =
          "Fehler beim Anlegen: " + (res.error || "Unbekannter Fehler");
        return;
      }
      this.addForm = {
        ipl_name: "",
        ipl: "",
        posx: null,
        posy: null,
        posz: null,
        exit_x: null,
        exit_y: null,
        exit_z: null,
      };
      await this.reloadAll();
    },

    // EDIT
    openEdit(row) {
      this.editDialog.visible = true;
      this.editDialog.busy = false;
      this.editDialog.error = null;
      this.editDialog.form = {
        id: row.id,
        ipl_name: row.ipl_name,
        ipl: row.ipl || "",
        posx: row.posx,
        posy: row.posy,
        posz: row.posz,
        exit_x: row.exit_x,
        exit_y: row.exit_y,
        exit_z: row.exit_z,
      };
    },

    async editSetSpawn() {
      await this.setSpawnFromPlayer(this.editDialog.form);
    },

    async editSetExit() {
      await this.setExitFromPlayer(this.editDialog.form);
    },

    async submitEdit() {
      const f = this.editDialog.form;
      if (!f.ipl_name.trim()) {
        this.editDialog.error = "IPL Name ist erforderlich.";
        return;
      }
      this.editDialog.busy = true;
      const res = await this.nuiCall("LCV:ADMIN:HousesIPL:Update", {
        id: f.id,
        ipl_name: f.ipl_name.trim(),
        ipl: f.ipl ? f.ipl.trim() : "",
        posx: f.posx,
        posy: f.posy,
        posz: f.posz,
        exit_x: f.exit_x,
        exit_y: f.exit_y,
        exit_z: f.exit_z,
      });
      this.editDialog.busy = false;

      if (!res.ok) {
        this.editDialog.error =
          "Fehler beim Speichern: " + (res.error || "Unbekannter Fehler");
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

    // DELETE
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
      const res = await this.nuiCall("LCV:ADMIN:HousesIPL:Delete", {
        id: this.deleteConfirm.row.id,
      });
      this.deleteConfirm.busy = false;

      if (!res.ok) {
        this.deleteConfirm.error =
          "Fehler beim Löschen: " + (res.error || "Unbekannter Fehler");
        return;
      }

      this.cancelDelete();
      await this.reloadAll();
    },

    // TELEPORT zu posx/posy/posz
    async teleport(row) {
      await this.nuiCall("LCV:ADMIN:HousesIPL:Teleport", {
        id: row.id,
        x: row.posx,
        y: row.posy,
        z: row.posz,
      });
    },
  },

  template: `
    <div class="options">
      <div class="interaction-header">
        <h1>Houses IPL</h1>
        <div class="header-buttons">
          <button class="refresh-btn" @click="reloadAll">
            <i class="fa-solid fa-rotate"></i> Reload
          </button>
        </div>
      </div>

      <p class="hint">
        Interiors / IPLs für Häuser. Spawn = Innenposition, Ausgang = Exit zurück zur Welt.
      </p>

      <div v-if="loading" class="status">Lade IPLs ...</div>
      <div v-else-if="error" class="status error">Fehler: {{ error }}</div>

      <div v-else class="table-wrapper">
        <table v-if="ipls.length" class="table-interactions">
          <thead>
            <tr>
              <th>ID</th>
              <th>IPL Name</th>
              <th>Spawn (posx/posy/posz)</th>
              <th>Exit (exit_x/y/z)</th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in ipls" :key="row.id">
              <td>{{ row.id }}</td>
              <td>{{ row.ipl_name }}</td>
              <td>{{ row.posx.toFixed(2) }}, {{ row.posy.toFixed(2) }}, {{ row.posz.toFixed(2) }}</td>
              <td>{{ row.exit_x.toFixed(2) }}, {{ row.exit_y.toFixed(2) }}, {{ row.exit_z.toFixed(2) }}</td>
              <td class="actions">
                <button class="btn-icon" title="Teleport" @click="teleport(row)">
                  <i class="fa-solid fa-location-arrow"></i>
                </button>
                <button class="btn-icon" title="Bearbeiten" @click="openEdit(row)">
                  <i class="fa-solid fa-pen"></i>
                </button>
                <button class="btn-icon danger" title="Löschen" @click="openDelete(row)">
                  <i class="fa-solid fa-trash"></i>
                </button>
              </td>
            </tr>
          </tbody>
        </table>

        <div v-if="!ipls.length" class="status">
          Keine IPLs vorhanden.
        </div>
      </div>

      <!-- ADD FORM -->
      <div class="add-form">
        <h2>Neues IPL anlegen</h2>

        <div class="add-grid">
          <div class="field">
            <label>IPL Name</label>
            <input v-model="addForm.ipl_name" type="text" placeholder="z.B. apartment_1" />
          </div>
          <div class="field">
  <label>IPL (interner Name)</label>
  <input v-model="addForm.ipl" type="text" />
</div>

        </div>

        <div class="field">
          <label>Spawn setzen (Innenposition)</label>
          <div class="pos-row">
            <input :value="addForm.posx || ''" placeholder="X" readonly />
            <input :value="addForm.posy || ''" placeholder="Y" readonly />
            <input :value="addForm.posz || ''" placeholder="Z" readonly />
            <button class="pos-btn" @click="setSpawnFromPlayer(addForm)">
              <i class="fa-solid fa-location-crosshairs"></i>Spawn setzen
            </button>
          </div>
        </div>

        <div class="field">
          <label>Ausgang setzen</label>
          <div class="pos-row">
            <input :value="addForm.exit_x || ''" placeholder="X" readonly />
            <input :value="addForm.exit_y || ''" placeholder="Y" readonly />
            <input :value="addForm.exit_z || ''" placeholder="Z" readonly />
            <button class="pos-btn" @click="setExitFromPlayer(addForm)">
              <i class="fa-solid fa-location-crosshairs"></i>Ausgang setzen
            </button>
          </div>
        </div>

        <div class="add-actions">
          <div class="error" v-if="addError">{{ addError }}</div>
          <button class="add-save-btn" @click="submitAdd">
            <i class="fa-solid fa-save"></i>Speichern
          </button>
        </div>
      </div>

      <!-- EDIT MODAL -->
      <div v-if="editDialog.visible" class="modal-backdrop">
        <div class="modal">
          <h3>IPL bearbeiten #{{ editDialog.form.id }}</h3>
          <div class="modal-error" v-if="editDialog.error">
            {{ editDialog.error }}
          </div>

          <div class="field">
            <label>IPL Name</label>
            <input v-model="editDialog.form.ipl_name" type="text" />
          </div>
          <div class="field">
  <label>IPL (interner Name)</label>
  <input v-model="editDialog.form.ipl" type="text" />
</div>


          <div class="field">
            <label>Spawn</label>
            <div class="pos-row">
              <input v-model="editDialog.form.posx" />
              <input v-model="editDialog.form.posy" />
              <input v-model="editDialog.form.posz" />
              <button class="pos-btn" @click="editSetSpawn">
                <i class="fa-solid fa-location-crosshairs"></i>Spawn
              </button>
            </div>
          </div>

          <div class="field">
            <label>Ausgang</label>
            <div class="pos-row">
              <input v-model="editDialog.form.exit_x" />
              <input v-model="editDialog.form.exit_y" />
              <input v-model="editDialog.form.exit_z" />
              <button class="pos-btn" @click="editSetExit">
                <i class="fa-solid fa-location-crosshairs"></i>Exit
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
          <h3>IPL löschen?</h3>
          <p v-if="deleteConfirm.row">
            IPL <strong>#{{ deleteConfirm.row.id }} - {{ deleteConfirm.row.ipl_name }}</strong> wirklich löschen?
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
    </div>
  `,
});
