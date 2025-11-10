Vue.component("tab-faction_perms", {
  props: ["identity"],
  data() {
    return {
      loading: false,
      error: null,
      perms: [],
      editingId: null,
      newRow: this.emptyRow(),
    };
  },
  methods: {
    getResName() {
      return typeof GetParentResourceName === "function"
        ? GetParentResourceName()
        : "admin-menu";
    },

    emptyRow() {
      return {
        id: null,
        perm_key: "",
        label: "",
        allowed_text: "",
        sort_index: 100,
        is_active: true,
      };
    },

    async loadPerms() {
      this.loading = true;
      this.error = null;
      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:FactionPerms:GetAll`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify({}),
          }
        );
        const data = await res.json();
        if (!data || !data.ok) {
          this.error = (data && data.error) || "Fehler beim Laden.";
          this.perms = [];
        } else {
          this.perms = (data.perms || []).map((p) => ({
            id: p.id,
            perm_key: p.perm_key,
            label: p.label,
            allowed_text: p.allowed_text || "",
            sort_index: Number(p.sort_index) || 100,
            is_active: !!p.is_active,
          }));
        }
      } catch (e) {
        this.error = "Konnte Schema nicht laden.";
        this.perms = [];
      }
      this.loading = false;
    },

    startEdit(p) {
      this.editingId = p.id;
    },

    cancelEdit() {
      this.editingId = null;
      // Neu laden, um evtl. veränderte Inputs zu resetten
      this.loadPerms();
    },

    async saveExisting(p) {
      this.error = null;
      if (!p.perm_key || !p.label) {
        this.error = "perm_key und Label sind erforderlich.";
        return;
      }

      const payload = {
        id: p.id,
        perm_key: p.perm_key,
        label: p.label,
        allowed_text: p.allowed_text || "",
        sort_index: Number(p.sort_index) || 100,
        is_active: !!p.is_active,
      };

      const res = await fetch(
        `https://${this.getResName()}/LCV:ADMIN:FactionPerms:Save`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify(payload),
        }
      );
      const data = await res.json();
      if (!data || !data.ok) {
        this.error = (data && data.error) || "Fehler beim Speichern.";
        return;
      }

      this.perms = (data.perms || []).map((p) => ({
        id: p.id,
        perm_key: p.perm_key,
        label: p.label,
        allowed_text: p.allowed_text || "",
        sort_index: Number(p.sort_index) || 100,
        is_active: !!p.is_active,
      }));
      this.editingId = null;
    },

    async addNew() {
      this.error = null;
      const p = this.newRow;
      if (!p.perm_key || !p.label) {
        this.error = "perm_key und Label sind erforderlich.";
        return;
      }

      const payload = {
        perm_key: p.perm_key,
        label: p.label,
        allowed_text: p.allowed_text || "",
        sort_index: Number(p.sort_index) || 100,
        is_active: !!p.is_active,
      };

      const res = await fetch(
        `https://${this.getResName()}/LCV:ADMIN:FactionPerms:Save`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify(payload),
        }
      );
      const data = await res.json();
      if (!data || !data.ok) {
        this.error = (data && data.error) || "Fehler beim Anlegen.";
        return;
      }

      this.perms = (data.perms || []).map((p) => ({
        id: p.id,
        perm_key: p.perm_key,
        label: p.label,
        allowed_text: p.allowed_text || "",
        sort_index: Number(p.sort_index) || 100,
        is_active: !!p.is_active,
      }));
      this.newRow = this.emptyRow();
    },

    async deletePerm(p) {
      if (!p.id) return;
      this.error = null;

      const res = await fetch(
        `https://${this.getResName()}/LCV:ADMIN:FactionPerms:Delete`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify({ id: p.id }),
        }
      );
      const data = await res.json();
      if (!data || !data.ok) {
        this.error = (data && data.error) || "Fehler beim Löschen.";
        return;
      }

      this.perms = (data.perms || []).map((p) => ({
        id: p.id,
        perm_key: p.perm_key,
        label: p.label,
        allowed_text: p.allowed_text || "",
        sort_index: Number(p.sort_index) || 100,
        is_active: !!p.is_active,
      }));
      if (this.editingId === p.id) {
        this.editingId = null;
      }
    },
  },
  mounted() {
    this.loadPerms();
  },
  template: `
    <div class="options">
      <div class="interaction-header">
        <div>
          <h2 style="margin:0; font-size:14px;">Faction Permission Schema</h2>
          <p class="hint">
            Verwalte globale Fraktionsrechte. Diese Optionen erscheinen im Fraktions-Tab pro Rang.
          </p>
        </div>
        <div class="header-buttons">
          <button class="refresh-btn" @click="loadPerms">
            <i class="fa fa-rotate"></i>
          </button>
        </div>
      </div>

      <div v-if="loading" class="status">Lade Permission-Schema...</div>
      <div v-if="error" class="status error">{{ error }}</div>

      <div class="table-wrapper" v-if="!loading">
        <table class="table-interactions">
          <thead>
            <tr>
              <th style="width:40px;">ID</th>
              <th>perm_key</th>
              <th>Label</th>
              <th>Factions (optional)</th>
              <th>Sort</th>
              <th>Aktiv</th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <!-- EXISTING ROWS -->
            <tr v-for="p in perms" :key="p.id">
              <td>{{ p.id }}</td>
              <td>
                <input
                  v-model="p.perm_key"
                  :disabled="editingId !== p.id"
                  class="rank-input"
                  style="width:120px;"
                />
              </td>
              <td>
                <input
                  v-model="p.label"
                  :disabled="editingId !== p.id"
                  class="rank-input"
                  style="width:180px;"
                />
              </td>
              <td>
                <input
                  v-model="p.allowed_text"
                  :disabled="editingId !== p.id"
                  class="rank-input"
                  placeholder="z.B. LSPD,LSMD oder leer = alle"
                  style="width:180px;"
                />
              </td>
              <td>
                <input
                  type="number"
                  v-model.number="p.sort_index"
                  :disabled="editingId !== p.id"
                  class="rank-level-input"
                  style="width:60px;"
                />
              </td>
              <td style="text-align:center;">
                <input
                  type="checkbox"
                  v-model="p.is_active"
                  :disabled="editingId !== p.id"
                />
              </td>
              <td class="col-actions">
                <div class="actions">
                  <button
                    v-if="editingId !== p.id"
                    class="btn-icon"
                    @click="startEdit(p)"
                    title="Bearbeiten"
                  >
                    <i class="fa fa-pen"></i>
                  </button>
                  <button
                    v-else
                    class="btn-icon"
                    @click="saveExisting(p)"
                    title="Speichern"
                  >
                    <i class="fa fa-save"></i>
                  </button>
                  <button
                    v-if="editingId === p.id"
                    class="btn-icon"
                    @click="cancelEdit"
                    title="Abbrechen"
                  >
                    <i class="fa fa-xmark"></i>
                  </button>
                  <button
                    class="btn-icon danger"
                    @click="deletePerm(p)"
                    title="Löschen"
                  >
                    <i class="fa fa-trash"></i>
                  </button>
                </div>
              </td>
            </tr>

            <!-- NEW ROW -->
            <tr>
              <td>neu</td>
              <td>
                <input
                  v-model="newRow.perm_key"
                  class="rank-input"
                  placeholder="z.B. lspd_armory"
                  style="width:120px;"
                />
              </td>
              <td>
                <input
                  v-model="newRow.label"
                  class="rank-input"
                  placeholder="Anzeigename"
                  style="width:180px;"
                />
              </td>
              <td>
                <input
                  v-model="newRow.allowed_text"
                  class="rank-input"
                  placeholder="LSPD,LSMD oder leer"
                  style="width:180px;"
                />
              </td>
              <td>
                <input
                  type="number"
                  v-model.number="newRow.sort_index"
                  class="rank-level-input"
                  style="width:60px;"
                />
              </td>
              <td style="text-align:center;">
                <input type="checkbox" v-model="newRow.is_active" />
              </td>
              <td class="col-actions">
                <button class="btn-icon" @click="addNew" title="Hinzufügen">
                  <i class="fa fa-plus"></i>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="status" style="font-size:9px; margin-top:4px;">
        Hinweis: <strong>Factions (optional)</strong> = Kommagetrennte Liste von Fraktions-Keys (factions.name).
        Wenn leer, ist die Permission für alle Fraktionen sichtbar.
      </div>
    </div>
  `,
});
