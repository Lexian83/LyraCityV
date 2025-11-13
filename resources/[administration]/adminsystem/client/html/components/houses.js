Vue.component("tab-houses", {
  props: ["identity"],
  data() {
    return {
      loading: true,
      error: null,
      houses: [],
      ipls: [],
      editSpawns: { loading: false, error: null, list: [] },

      sortField: "id",
      sortDir: "asc",

      addMode: false,
      placementMode: false,

      addForm: {
        streetName: "",
        houseNumber: "",
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

        hotel: false,
        secured: false, // 👈 NEU
        apartments: 0,
        garage_size: 0,

        allowed_bike: true,
        allowed_motorbike: true,
        allowed_car: true,
        allowed_truck: false,
        allowed_plane: false,
        allowed_helicopter: false,
        allowed_boat: false,

        maxkeys: 0,
        pincode: "",
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

      pinMessage: "",
    };
  },

  mounted() {
    this.reloadAll();
  },

  methods: {
    async loadEditSpawns(houseId) {
      this.editSpawns.loading = true;
      this.editSpawns.error = null;
      try {
        if (!houseId) {
          // ⬅️ Guard
          this.editSpawns.list = [];
          return;
        }
        const res = await this.nuiCall("LCV:ADMIN:Houses:GarageSpawns:List", {
          id: houseId,
        });
        if (!res.ok) throw new Error(res.error || "Load failed");
        this.editSpawns.list = Array.isArray(res.spawns) ? res.spawns : [];
      } catch (e) {
        this.editSpawns.error = e.message || String(e);
        this.editSpawns.list = [];
      } finally {
        this.editSpawns.loading = false;
      }
    },

    async addSpawnFromPos() {
      if (!this.editDialog.visible || !this.editDialog.form?.id) {
        // ⬅️ Guard
        this.editSpawns.error =
          "Spawns erst nach dem Anlegen im Bearbeiten-Dialog hinzufügen.";
        return;
      }
      const pos = await this.nuiCall("LCV:ADMIN:Npcs:GetPlayerPos");
      if (!pos || !pos.ok) return alert("Position nicht verfügbar.");

      const payload = {
        id: this.editDialog.form.id,
        spawn: {
          type: "both",
          x: pos.x,
          y: pos.y,
          z: pos.z,
          heading: pos.heading || 0.0,
          radius: 3.0,
        },
      };
      const res = await this.nuiCall(
        "LCV:ADMIN:Houses:GarageSpawns:Add",
        payload
      );
      if (!res.ok)
        return alert("Spawn anlegen fehlgeschlagen: " + (res.error || "?"));
      this.editSpawns.list = res.spawns || this.editSpawns.list;
    },

    async deleteSpawn(sid) {
      if (!this.editDialog.visible || !this.editDialog.form?.id) {
        // ⬅️ Guard
        this.editSpawns.error = "Nur im Bearbeiten-Dialog möglich.";
      }
      const res = await this.nuiCall("LCV:ADMIN:Houses:GarageSpawns:Delete", {
        id: this.editDialog.form.id,
        sid,
      });
      if (!res.ok)
        return alert("Löschen fehlgeschlagen: " + (res.error || "?"));
      this.editSpawns.list = res.spawns || [];
    },

    async deleteSpawn(sid) {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GarageSpawns:Delete", {
        id: this.editDialog.form.id,
        sid,
      });
      if (!res.ok) {
        alert("Löschen fehlgeschlagen: " + (res.error || "?"));
        return;
      }
      this.editSpawns.list = res.spawns || [];
    },

    // ===== Helper =====
    toBool(value) {
      if (typeof value === "boolean") {
        return value;
      }
      if (typeof value === "number") {
        return value === 1;
      }
      if (typeof value === "string") {
        const v = value.trim().toLowerCase();
        return v === "1" || v === "true" || v === "yes" || v === "on";
      }
      return false;
    },

    composeName(street, number) {
      street = (street || "").trim();
      number = (number || "").trim();
      if (!street && !number) return "";
      if (!number) return street;
      return `${street} ${number}`;
    },

    splitName(full) {
      full = (full || "").trim();
      if (!full) return { streetName: "", houseNumber: "" };
      const m = full.match(/^(.*)\s+(\S+)$/);
      if (!m) return { streetName: full, houseNumber: "" };
      return { streetName: m[1], houseNumber: m[2] };
    },

    statusOf(h) {
      const hasOwner = h.ownerid && h.ownerid > 0;
      const hasRentStart = !!h.rent_start;
      if (!hasOwner) return "frei";
      if (hasOwner && !hasRentStart) return "verkauft";
      return "vermietet";
    },

    // ===== NUI Helper =====
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

    // ===== Load =====
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

    // ===== Sort =====
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

      list.sort((a, b) => {
        let va = a[f];
        let vb = b[f];

        if (f === "status") {
          va = this.statusOf(a);
          vb = this.statusOf(b);
        }

        if (va == null && vb != null) return -1 * dir;
        if (va != null && vb == null) return 1 * dir;
        if (va == null && vb == null) return 0;
        if (typeof va === "string") va = va.toLowerCase();
        if (typeof vb === "string") vb = vb.toLowerCase();
        if (va < vb) return -1 * dir;
        if (va > vb) return 1 * dir;
        return 0;
      });

      return list;
    },

    // ===== Placement Mode (1/3 Viewport) =====
    async setPlacementMode(enabled) {
      this.placementMode = !!enabled;
      await this.nuiCall("LCV:ADMIN:UI:SetPlacementMode", {
        enabled: this.placementMode,
      });
    },

    // ===== GET PLAYER POS =====
    async getPlayerPos() {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetPlayerPos");
      if (!res.ok) {
        alert("Konnte Spielerposition nicht holen: " + (res.error || "?"));
        return null;
      }
      return { x: res.x, y: res.y, z: res.z };
    },

    // ===== Add House (INLINE) =====
    startAdd() {
      // Nur ein Formular aktiv
      this.editDialog.visible = false;
      this.deleteConfirm.visible = false;

      this.addMode = true;
      this.addError = null;
      this.setPlacementMode(true);

      this.addForm = {
        streetName: "",
        houseNumber: "",
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

        hotel: false,
        apartments: 0,
        garage_size: 0,

        allowed_bike: true,
        allowed_motorbike: true,
        allowed_car: true,
        allowed_truck: false,
        allowed_plane: false,
        allowed_helicopter: false,
        allowed_boat: false,

        maxkeys: 0,
        pincode: "",
      };
    },

    cancelAdd() {
      this.addMode = false;
      this.addError = null;
      this.setPlacementMode(false);
    },

    async setAddEntry() {
      const pos = await this.getPlayerPos();
      if (!pos) return;
      this.addForm.entry_x = pos.x;
      this.addForm.entry_y = pos.y;
      this.addForm.entry_z = pos.z;
    },

    async setAddGarageTrigger() {
      const pos = await this.getPlayerPos();
      if (!pos) return;
      this.addForm.garage_trigger_x = pos.x;
      this.addForm.garage_trigger_y = pos.y;
      this.addForm.garage_trigger_z = pos.z;
    },

    async setAddGarageSpawn() {
      const pos = await this.getPlayerPos();
      if (!pos) return;
      this.addForm.garage_x = pos.x;
      this.addForm.garage_y = pos.y;
      this.addForm.garage_z = pos.z;
    },

    async getStreetNameFromPlayer() {
      const res = await this.nuiCall("LCV:ADMIN:Houses:GetStreetName");
      if (res.ok && res.street) {
        this.addForm.streetName = res.street;
      }
    },

    async saveAdd() {
      try {
        this.addError = null;

        const name = this.composeName(
          this.addForm.streetName,
          this.addForm.houseNumber
        );
        if (!name) {
          this.addError = "Bitte Straßenname/Hausnummer setzen.";
          return;
        }
        if (!this.addForm.entry_x) {
          this.addError = "Bitte Eingang setzen.";
          return;
        }

        const p = this.addForm;
        const payload = {
          name,
          ownerid: this.addForm.ownerid || null,
          price: Number(this.addForm.price) || 0,
          rent: Number(this.addForm.rent) || 0,
          ipl: this.addForm.ipl || null,
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

          hotel: this.addForm.hotel ? 1 : 0,
          secured: this.addForm.secured ? 1 : 0, // 👈 NEU
          apartments: Number(this.addForm.apartments) || 0,
          garage_size: Number(this.addForm.garage_size) || 0,

          allowed_bike: this.addForm.allowed_bike ? 1 : 0,
          allowed_motorbike: this.addForm.allowed_motorbike ? 1 : 0,
          allowed_car: this.addForm.allowed_car ? 1 : 0,
          allowed_truck: this.addForm.allowed_truck ? 1 : 0,
          allowed_plane: this.addForm.allowed_plane ? 1 : 0,
          allowed_helicopter: this.addForm.allowed_helicopter ? 1 : 0,
          allowed_boat: this.addForm.allowed_boat ? 1 : 0,

          maxkeys: Number(this.addForm.maxkeys) || 0,
          pincode: this.addForm.pincode || "",
        };

        const res = await this.nuiCall("LCV:ADMIN:Houses:Add", payload);
        if (!res.ok) {
          this.addError = res.error || "Fehler beim Speichern.";
          return;
        }

        this.addMode = false;
        this.setPlacementMode(false);
        await this.reloadAll();
      } catch (e) {
        console.error(e);
        this.addError = e.message || String(e);
      }
    },

    // ===== Edit (INLINE) =====
    openEdit(h) {
      const ns = this.splitName(h.name || "");

      // Nur Edit-Form anzeigen
      this.addMode = false;
      this.deleteConfirm.visible = false;

      this.editDialog.visible = true;
      this.editDialog.error = null;
      this.editDialog.busy = false;

      // Lokaler Helper: robustes Boolean + Default
      const asBool = (val, def = false) => {
        if (val === null || typeof val === "undefined") return def;
        if (typeof val === "boolean") return val;
        if (typeof val === "number") return val === 1;
        const v = String(val).trim().toLowerCase();
        return v === "1" || v === "true" || v === "yes" || v === "on";
      };

      this.editDialog.form = {
        id: h.id,

        // Name gesplittet
        streetName: ns.streetName,
        houseNumber: ns.houseNumber,

        ownerid: h.ownerid || "",
        price: h.price || 0,
        rent: h.rent || 0,
        ipl: h.ipl || "",

        entry_x: h.entry_x,
        entry_y: h.entry_y,
        entry_z: h.entry_z,

        garage_trigger_x: h.garage_trigger_x,
        garage_trigger_y: h.garage_trigger_y,
        garage_trigger_z: h.garage_trigger_z,

        garage_x: h.garage_x,
        garage_y: h.garage_y,
        garage_z: h.garage_z,

        // vom Server kommt interaction_radius, fallback auf 0.5
        radius: h.interaction_radius || h.radius || 0.5,

        // Hotel & Apartments
        hotel: asBool(h.hotel, false),
        secured:
          h.secured === 1 || h.secured === true || String(h.secured) === "1", // 👈 NEU
        apartments: h.apartments || 0,
        garage_size: h.garage_size || 0,

        // Allowed Vehicles (Defaults wie im Add-Form)
        allowed_bike: asBool(h.allowed_bike, true),
        allowed_motorbike: asBool(h.allowed_motorbike, true),
        allowed_car: asBool(h.allowed_car, true),
        allowed_truck: asBool(h.allowed_truck, false),
        allowed_plane: asBool(h.allowed_plane, false),
        allowed_helicopter: asBool(h.allowed_helicopter, false),
        allowed_boat: asBool(h.allowed_boat, false),

        maxkeys: h.maxkeys || 0,
        pincode: h.pincode || "",
      };

      this.setPlacementMode(true);
      this.loadEditSpawns(h.id);
    },

    async editSetEntry() {
      const pos = await this.getPlayerPos();
      if (!pos) return;
      const f = this.editDialog.form;
      f.entry_x = pos.x;
      f.entry_y = pos.y;
      f.entry_z = pos.z;
    },

    async editSetGarageTrigger() {
      const pos = await this.getPlayerPos();
      if (!pos) return;
      const f = this.editDialog.form;
      f.garage_trigger_x = pos.x;
      f.garage_trigger_y = pos.y;
      f.garage_trigger_z = pos.z;
    },

    async editSetGarageSpawn() {
      const pos = await this.getPlayerPos();
      if (!pos) return;
      const f = this.editDialog.form;
      f.garage_x = pos.x;
      f.garage_y = pos.y;
      f.garage_z = pos.z;
    },

    async saveEdit() {
      const f = this.editDialog.form;
      this.editDialog.busy = true;
      this.editDialog.error = null;

      try {
        const name = this.composeName(f.streetName, f.houseNumber);
        if (!name) {
          this.editDialog.error = "Bitte Straßenname/Hausnummer setzen.";
          this.editDialog.busy = false;
          return;
        }

        const payload = {
          id: f.id,
          name,
          ownerid: f.ownerid || null,
          price: Number(f.price) || 0,
          rent: Number(f.rent) || 0,
          ipl: f.ipl || null,

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

          hotel: f.hotel ? 1 : 0,
          secured: f.secured ? 1 : 0, // 👈 NEU
          apartments: Number(f.apartments) || 0,
          garage_size: Number(f.garage_size) || 0,

          allowed_bike: f.allowed_bike ? 1 : 0,
          allowed_motorbike: f.allowed_motorbike ? 1 : 0,
          allowed_car: f.allowed_car ? 1 : 0,
          allowed_truck: f.allowed_truck ? 1 : 0,
          allowed_plane: f.allowed_plane ? 1 : 0,
          allowed_helicopter: f.allowed_helicopter ? 1 : 0,
          allowed_boat: f.allowed_boat ? 1 : 0,

          maxkeys: Number(f.maxkeys) || 0,
          pincode: f.pincode || "",
        };

        const res = await this.nuiCall("LCV:ADMIN:Houses:Update", payload);
        if (!res.ok) {
          this.editDialog.error = res.error || "Fehler beim Speichern.";
          this.editDialog.busy = false;
          return;
        }

        this.editDialog.visible = false;
        this.setPlacementMode(false);
        await this.reloadAll();
      } catch (e) {
        console.error(e);
        this.editDialog.error = e.message || String(e);
      } finally {
        this.editDialog.busy = false;
      }
    },

    cancelEdit() {
      this.editDialog.visible = false;
      this.editDialog.error = null;
      this.setPlacementMode(false);
    },

    // ===== Delete =====
    askDelete(h) {
      this.deleteConfirm.visible = true;
      this.deleteConfirm.row = h;
      this.deleteConfirm.busy = false;
      this.deleteConfirm.error = null;
    },

    async doDelete() {
      const row = this.deleteConfirm.row;
      if (!row || this.deleteConfirm.busy) return;

      this.deleteConfirm.busy = true;
      const res = await this.nuiCall("LCV:ADMIN:Houses:Delete", { id: row.id });
      this.deleteConfirm.busy = false;

      if (!res.ok) {
        this.deleteConfirm.error = res.error || "Fehler beim Löschen.";
        return;
      }

      this.deleteConfirm.visible = false;
      this.deleteConfirm.row = null;
      await this.reloadAll();
    },

    cancelDelete() {
      this.deleteConfirm.visible = false;
      this.deleteConfirm.row = null;
      this.deleteConfirm.busy = false;
      this.deleteConfirm.error = null;
    },

    // ===== Teleport & PIN =====
    async teleportTo(h) {
      if (!h.entry_x) return;
      await this.nuiCall("LCV:ADMIN:Houses:Teleport", {
        id: h.id,
        x: h.entry_x,
        y: h.entry_y,
        z: h.entry_z,
      });
    },

    async resetPincode(h) {
      const res = await this.nuiCall("LCV:ADMIN:Houses:ResetPincode", {
        id: h.id,
      });
      if (!res.ok) {
        alert("PIN-Reset fehlgeschlagen: " + (res.error || "?"));
        return;
      }
      this.pinMessage = `Pincode für Haus #${h.id} wurde zurückgesetzt.`;
      setTimeout(() => {
        this.pinMessage = "";
      }, 3000);
      await this.reloadAll();
    },
  },

  template: `
    <div class="options">
      <div class="interaction-header">
        <h1>Häuser</h1>
        <div class="header-buttons">
          <button class="refresh-btn" @click="reloadAll">
            <i class="fa-solid fa-rotate"></i> Reload
          </button>
          <button class="add-btn" @click="startAdd">
            <i class="fa-solid fa-plus"></i> Neues Haus
          </button>
        </div>
      </div>

      <p class="hint">
        Verwaltung aller Häuser. Inline-Erstellung/-Bearbeitung, Ansicht skaliert auf 1/3 wie bei Houses_IPL.
      </p>

      <div v-if="loading" class="status">Lade Häuser ...</div>
      <div v-else-if="error" class="status error">Fehler: {{ error }}</div>

      <div v-if="pinMessage" class="status success">{{ pinMessage }}</div>

      <div v-else class="table-wrapper">
        <table v-if="sortedHouses().length" class="table-interactions">
          <thead>
            <tr>
              <th class="sortable" @click="setSort('id')">
                ID <span class="sort-indicator">{{ sortIndicator('id') }}</span>
              </th>
              <th class="sortable" @click="setSort('name')">
                Name <span class="sort-indicator">{{ sortIndicator('name') }}</span>
              </th>
              <th class="col-center" title="Gesichert">🔒</th>
              <th class="sortable" @click="setSort('ownerid')">
                Owner <span class="sort-indicator">{{ sortIndicator('ownerid') }}</span>
              </th>
              <th class="sortable" @click="setSort('status')">
                Status <span class="sort-indicator">{{ sortIndicator('status') }}</span>
              </th>
              <th>Preis</th>
              <th>Miete</th>
              <th>Hotel</th>
              <th>Apts</th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="h in sortedHouses()" :key="h.id">
              <td>{{ h.id }}</td>
              <td class="data-cell">{{ h.name }}</td>
              <td class="col-center">
  <span
    v-if="h.secured === 1 || h.secured === true || String(h.secured) === '1'"
    class="badge-secured"
    title="Gesichert"
  >🔒</span>
  <span
    v-else
    class="badge-not-secured"
    title="Nicht gesichert"
  >—</span>
</td>

              <td>{{ h.ownerid || '-' }}</td>
              <td>{{ statusOf(h) }}</td>
              <td>{{ h.price || 0 }}</td>
              <td>{{ h.rent || 0 }}</td>
              <td>{{ toBool(h.hotel) ? 'Ja' : '-' }}</td>
              <td>{{ h.apartments || 0 }}</td>
              <td>
                <div class="actions">
                  <button class="btn-icon" @click="teleportTo(h)" title="Teleport">
                    <i class="fas fa-location-arrow"></i>
                  </button>
                  <button class="btn-icon" @click="openEdit(h)" title="Bearbeiten">
                    <i class="fas fa-pen"></i>
                  </button>
                  <button class="btn-icon danger" @click="askDelete(h)" title="Löschen">
                    <i class="fas fa-trash"></i>
                  </button>
                  <button class="btn-icon" @click="resetPincode(h)" title="PIN zurücksetzen">
                    <i class="fas fa-key"></i>
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="sortedHouses().length === 0">
              <td colspan="9" class="hint">Noch keine Häuser angelegt.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- INLINE ADD FORM -->
      <div v-if="addMode" class="add-form">
        <h2>Neues Haus anlegen</h2>

        <!-- Zeile 1 -->
        <div class="form-row cols-3">
          <div class="field">
            <label>Straßenname</label>
            <input v-model="addForm.streetName" />
          </div>
          <div class="field">
            <label>Hausnummer</label>
            <input v-model="addForm.houseNumber" />
          </div>
          <div class="field">
            <label>Straßenname von Pos</label>
            <button class="pos-btn" type="button" @click="getStreetNameFromPlayer">
              Straßenname
            </button>
          </div>
        </div>

        <!-- Zeile 2 -->
        <div class="form-row cols-3">
          <div class="field">
            <label>Miete</label>
            <input v-model.number="addForm.rent" type="number" />
          </div>
          <div class="field">
            <label>Preis</label>
            <input v-model.number="addForm.price" type="number" />
          </div>
          <div class="field">
            <label>IPL</label>
            <select v-model="addForm.ipl">
              <option value="">- kein -</option>
              <option v-for="i in ipls" :key="i.id" :value="i.id">
                {{ i.id }} - {{ i.ipl_name }}
              </option>
            </select>
          </div>
        </div>

        <!-- Zeile 3 -->
        <div class="form-row cols-2">
          <div class="field">
            <label>Hotel</label>
            <div class="switch" :class="{ on: !!addForm.hotel }"
                 @click="addForm.hotel = !addForm.hotel">
              <div class="knob"></div>
            </div>
          </div>
            <div class="field">
    <label>Gesichert</label> <!-- 👈 NEU -->
    <div class="switch" :class="{ on: !!addForm.secured }"
         @click="addForm.secured = !addForm.secured">
      <div class="knob"></div>
    </div>
  </div>
          <div class="field">
            <label>Apartments</label>
            <input v-model.number="addForm.apartments" type="number" min="0" />
          </div>
        </div>

        <!-- Zeile 4 -->
        <div class="form-row cols-2">
          <div class="field">
            <label>Garage Size</label>
            <input v-model.number="addForm.garage_size" type="number" min="0" />
          </div>
          <div class="field">
            <label>Max Keys</label>
            <input v-model.number="addForm.maxkeys" type="number" min="0" />
          </div>
        </div>

        <!-- Zeile 5 -->
        <div class="form-row cols-3">
          <div class="field">
            <label>Radius</label>
            <input v-model.number="addForm.radius" type="number" step="0.1" />
          </div>
          <div class="field">
            <label>OwnerID</label>
            <input v-model.number="addForm.ownerid" type="number" />
          </div>
          <div class="field">
            <label>Pincode (4-stellig)</label>
            <input v-model="addForm.pincode" maxlength="4" />
          </div>
        </div>

        <!-- Zeile 6 -->
        <div class="form-row cols-3">
          <div class="field">
            <label>Eingang</label>
            <button class="pos-btn" type="button" @click="setAddEntry">Set from Pos</button>
          </div>
          <div class="field">
            <label>Garage Trigger</label>
            <button class="pos-btn" type="button" @click="setAddGarageTrigger">Set from Pos</button>
          </div>
          <div class="field">
            <label>Garage Spawn</label>
            <button class="pos-btn" type="button" @click="setAddGarageSpawn">Set from Pos</button>
          </div>
        </div>

        <!-- Zeile 7 -->
        <div class="form-row cols-1">
          <div class="field">
            <label>Allowed Vehicles</label>
            <div class="inline">
              <label><input type="checkbox" v-model="addForm.allowed_bike" /> BIKE</label>
              <label><input type="checkbox" v-model="addForm.allowed_motorbike" /> MOTO</label>
              <label><input type="checkbox" v-model="addForm.allowed_car" /> CAR</label>
              <label><input type="checkbox" v-model="addForm.allowed_truck" /> TRUCK</label>
              <label><input type="checkbox" v-model="addForm.allowed_plane" /> PLANE</label>
              <label><input type="checkbox" v-model="addForm.allowed_helicopter" /> HELI</label>
              <label><input type="checkbox" v-model="addForm.allowed_boat" /> BOAT</label>
            </div>
          </div>
        </div>
<!-- Zeile: Garage Spawns -->
<div v-if="editDialog.visible && editDialog.form?.id"  class="form-row cols-1">
  <div class="field">
    <label>Garage-Ein-/Ausparkpunkte</label>

    <div class="add-actions" style="margin: 4px 0;">
      <div class="status" v-if="editSpawns.loading">Lade Spawns ...</div>
      <div class="error" v-if="editSpawns.error">{{ editSpawns.error }}</div>
      <div class="btn-row">
        <button class="modal-btn" type="button"
        :disabled="!editDialog.form?.id"
        @click="addSpawnFromPos">
  + Spawn von Spieler-Position
</button>

        <button class="modal-btn" type="button" @click="loadEditSpawns(editDialog.form.id)">
          Reload Spawns
        </button>
      </div>
    </div>

    <ul class="mini-list" v-if="!editSpawns.loading && editSpawns.list.length">
      <li class="mini-row" v-for="s in editSpawns.list" :key="s.sid">
        <div>
          <div class="mini-title">
            #{{ s.sid }} — {{ s.label || 'Spawn' }} ({{ s.type || 'both' }})
          </div>
          <div class="mini-sub">
            x: {{ Number(s.x).toFixed(2) }},
            y: {{ Number(s.y).toFixed(2) }},
            z: {{ Number(s.z).toFixed(2) }},
            h: {{ Number(s.heading || 0).toFixed(1) }},
            r: {{ Number(s.radius || 3).toFixed(1) }}
          </div>
        </div>
        <button class="mini-btn danger" @click="deleteSpawn(s.sid)">Löschen</button>
      </li>
    </ul>

    <div class="hint" v-if="!editSpawns.loading && !editSpawns.list.length">
      Noch keine Spawns angelegt.
    </div>
  </div>
</div>

        <!-- Zeile 9 -->
        <div class="add-actions">
          <div class="error" v-if="addError">{{ addError }}</div>
          <div class="btn-row">
            <button class="modal-btn" type="button" @click="cancelAdd">Abbrechen</button>
            <button class="add-save-btn" type="button" @click="saveAdd">
              <i class="fa-solid fa-save"></i> Speichern
            </button>
          </div>
        </div>
      </div>

      <!-- INLINE EDIT FORM -->
      <div v-if="editDialog.visible" class="add-form">
        <h2>Haus bearbeiten #{{ editDialog.form.id }}</h2>

        <!-- Zeile 1 -->
        <div class="form-row cols-3">
          <div class="field">
            <label>Straßenname</label>
            <input v-model="editDialog.form.streetName" />
          </div>
          <div class="field">
            <label>Hausnummer</label>
            <input v-model="editDialog.form.houseNumber" />
          </div>
          <div class="field">
            <label>&nbsp;</label>
          </div>
        </div>

        <!-- Zeile 2 -->
        <div class="form-row cols-3">
          <div class="field">
            <label>Miete</label>
            <input v-model.number="editDialog.form.rent" type="number" />
          </div>
          <div class="field">
            <label>Preis</label>
            <input v-model.number="editDialog.form.price" type="number" />
          </div>
          <div class="field">
            <label>IPL</label>
            <select v-model="editDialog.form.ipl">
              <option value="">- kein -</option>
              <option v-for="i in ipls" :key="i.id" :value="i.id">
                {{ i.id }} - {{ i.ipl_name }}
              </option>
            </select>
          </div>
        </div>

        <!-- Zeile 3 -->
        <div class="form-row cols-2">
          <div class="field">
            <label>Hotel</label>
            <div class="switch"
                 :class="{ on: !!editDialog.form.hotel }"
                 @click="editDialog.form.hotel = !editDialog.form.hotel">
              <div class="knob"></div>
            </div>
          </div>
            <div class="field">
    <label>Gesichert</label> <!-- 👈 NEU -->
    <div class="switch"
         :class="{ on: !!editDialog.form.secured }"
         @click="editDialog.form.secured = !editDialog.form.secured">
      <div class="knob"></div>
    </div>
  </div>
          <div class="field">
            <label>Apartments</label>
            <input v-model.number="editDialog.form.apartments" type="number" min="0" />
          </div>
        </div>

        <!-- Zeile 4 -->
        <div class="form-row cols-2">
          <div class="field">
            <label>Garage Size</label>
            <input v-model.number="editDialog.form.garage_size" type="number" min="0" />
          </div>
          <div class="field">
            <label>Max Keys</label>
            <input v-model.number="editDialog.form.maxkeys" type="number" min="0" />
          </div>
        </div>

        <!-- Zeile 5 -->
        <div class="form-row cols-3">
          <div class="field">
            <label>Radius</label>
            <input v-model.number="editDialog.form.radius" type="number" step="0.1" />
          </div>
          <div class="field">
            <label>OwnerID</label>
            <input v-model.number="editDialog.form.ownerid" type="number" />
          </div>
          <div class="field">
            <label>Pincode (4-stellig)</label>
            <input v-model="editDialog.form.pincode" maxlength="4" />
          </div>
        </div>

        <!-- Zeile 6 -->
        <div class="form-row cols-3">
          <div class="field">
            <label>Eingang</label>
            <button class="pos-btn" type="button" @click="editSetEntry">Set from Pos</button>
          </div>
          <div class="field">
            <label>Garage Trigger</label>
            <button class="pos-btn" type="button" @click="editSetGarageTrigger">Set from Pos</button>
          </div>
          <div class="field">
            <label>Garage Spawn</label>
            <button class="pos-btn" type="button" @click="editSetGarageSpawn">Set from Pos</button>
          </div>
        </div>

        <!-- Zeile 7 -->
        <div class="form-row cols-1">
          <div class="field">
            <label>Allowed Vehicles</label>
            <div class="inline">
              <label><input type="checkbox" v-model="editDialog.form.allowed_bike" /> BIKE</label>
              <label><input type="checkbox" v-model="editDialog.form.allowed_motorbike" /> MOTO</label>
              <label><input type="checkbox" v-model="editDialog.form.allowed_car" /> CAR</label>
              <label><input type="checkbox" v-model="editDialog.form.allowed_truck" /> TRUCK</label>
              <label><input type="checkbox" v-model="editDialog.form.allowed_plane" /> PLANE</label>
              <label><input type="checkbox" v-model="editDialog.form.allowed_helicopter" /> HELI</label>
              <label><input type="checkbox" v-model="editDialog.form.allowed_boat" /> BOAT</label>
            </div>
          </div>
        </div>

        <!-- Zeile 8 -->
        <div class="add-actions">
          <div class="error" v-if="editDialog.error">{{ editDialog.error }}</div>
          <div class="btn-row">
            <button class="modal-btn" type="button" @click="cancelEdit">Abbrechen</button>
            <button class="add-save-btn" type="button" :disabled="editDialog.busy" @click="saveEdit">
              <i class="fa-solid fa-save"></i> Speichern
            </button>
          </div>
        </div>
      </div>

      <!-- DELETE CONFIRM -->
      <div v-if="deleteConfirm.visible" class="modal-backdrop">
        <div class="modal">
          <h3>Haus löschen</h3>
          <p>Haus #{{ deleteConfirm.row && deleteConfirm.row.id }} wirklich löschen?</p>
          <div class="error" v-if="deleteConfirm.error">{{ deleteConfirm.error }}</div>
          <div class="btn-row">
            <button class="modal-btn" @click="cancelDelete">Abbrechen</button>
            <button class="modal-btn danger" :disabled="deleteConfirm.busy" @click="doDelete">
              Löschen
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
});
