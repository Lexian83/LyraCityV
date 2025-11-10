Vue.component("tab-character", {
  props: ["identity"],
  data() {
    return {
      loading: false,
      error: null,

      characters: [],

      showEditModal: false,
      showDeleteModal: false,

      editForm: {
        id: null,
        name: "",
        level: 0,
        is_locked: false,
        residence_permit: 0,
        online: false,
      },

      deleteTarget: null,

      searchTerm: "",
      sortKey: "id", // id, account_id, name, type, status, online
      sortDir: "desc",
    };
  },

  created() {
    this.fetchCharacters();
  },

  methods: {
    // ---------- Helpers ----------
    getResName() {
      if (typeof GetParentResourceName === "function") {
        return GetParentResourceName();
      }
      return "lcv-admin";
    },

    // ---------- Load ----------
    fetchCharacters() {
      this.loading = true;
      this.error = null;

      fetch(`https://${this.getResName()}/LCV:ADMIN:Characters:GetAll`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({}),
      })
        .then((res) => res.json())
        .then((data) => {
          if (!data || !data.ok) {
            this.error =
              (data && data.error) || "Konnte Characters nicht laden.";
            this.characters = [];
          } else {
            this.characters = data.characters || [];
          }
        })
        .catch(() => {
          this.error = "Konnte Anfrage nicht senden.";
          this.characters = [];
        })
        .finally(() => {
          this.loading = false;
        });
    },

    // ---------- Status ----------
    getStatusLabel(ch) {
      if (ch.is_locked) return "Ausgereist";
      if (!ch.residence_permit) return "Nicht Eingereist";
      return "Eingereist";
    },
    getStatusClass(ch) {
      if (ch.is_locked) return "status-badge status-locked"; // rot
      if (!ch.residence_permit) return "status-badge status-pending"; // orange
      return "status-badge status-active"; // grün
    },

    // ---------- Online ----------
    getOnlineLabel(ch) {
      return ch.online ? "ONLINE" : "OFFLINE";
    },
    getOnlineClass(ch) {
      return ch.online ? "online-badge on" : "online-badge off";
    },

    // ---------- Birthdate Anzeige ----------
    formatBirthdate(ch) {
      const v = ch.birthdate_iso || ch.birthdate;
      if (!v) return "-";

      // String Cases
      if (typeof v === "string") {
        // Bereits 'YYYY-MM-DD'
        if (/^\d{4}-\d{2}-\d{2}$/.test(v)) return v;

        // 'YYYY-MM-DDTHH:MM:SS' o.ä.
        const m = v.match(/^(\d{4})-(\d{2})-(\d{2})/);
        if (m) return `${m[1]}-${m[2]}-${m[3]}`;

        // Nur Zahlen => Timestamp als String
        if (/^\d+$/.test(v)) {
          return this.formatTimestamp(parseInt(v, 10));
        }

        // Fallback: zeig an, wie es ist
        return v;
      }

      // Number => Timestamp
      if (typeof v === "number") {
        return this.formatTimestamp(v);
      }

      return "-";
    },

    formatTimestamp(ts) {
      if (!ts) return "-";

      let ms = ts;

      // Wenn es eher Sekunden sind: in ms umrechnen
      if (ms < 1e11) {
        ms = ms * 1000;
      }

      const d = new Date(ms);
      if (Number.isNaN(d.getTime())) return "-";

      // UTC, damit kein Off-by-One durch Zeitzonen
      const y = d.getUTCFullYear();
      const m = String(d.getUTCMonth() + 1).padStart(2, "0");
      const day = String(d.getUTCDate()).padStart(2, "0");
      return `${y}-${m}-${day}`;
    },

    // ---------- Sortierung ----------
    setSort(key) {
      if (this.sortKey === key) {
        this.sortDir = this.sortDir === "asc" ? "desc" : "asc";
      } else {
        this.sortKey = key;
        // Default-Richtung etwas sinnvoll wählen
        if (key === "name" || key === "status") {
          this.sortDir = "asc";
        } else if (key === "online") {
          this.sortDir = "desc";
        } else {
          this.sortDir = "desc";
        }
      }
    },
    sortIcon(key) {
      if (this.sortKey !== key) return "";
      return this.sortDir === "asc" ? "▲" : "▼";
    },

    // ---------- Edit ----------
    openEdit(ch) {
      this.error = null;
      this.showEditModal = true;
      this.editForm = {
        id: ch.id,
        name: ch.name,
        level: Number(ch.level) || 0,
        is_locked: !!ch.is_locked,
        residence_permit: ch.residence_permit ? 1 : 0,
        online: !!ch.online,
      };
    },
    closeEditModal() {
      this.showEditModal = false;
      this.error = null;
    },
    toggleLocked() {
      this.editForm.is_locked = !this.editForm.is_locked;
    },

    saveCharacter() {
      if (!this.editForm.id) {
        this.error = "Ungültige Character-ID.";
        return;
      }

      const payload = {
        id: this.editForm.id,
        level: Number(this.editForm.level) || 0,
        is_locked: !!this.editForm.is_locked,
        residence_permit: Number(this.editForm.residence_permit) || 0,
      };

      fetch(`https://${this.getResName()}/LCV:ADMIN:Characters:Update`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(payload),
      })
        .then((res) => res.json())
        .then((data) => {
          if (!data || !data.ok) {
            this.error =
              (data && data.error) || "Fehler beim Speichern des Characters.";
            return;
          }

          const row = data.row;
          if (row) {
            const idx = this.characters.findIndex((c) => c.id === row.id);
            if (idx !== -1) {
              this.$set(this.characters, idx, row);
            } else {
              this.characters.unshift(row);
            }
          }

          this.showEditModal = false;
          this.error = null;
        })
        .catch(() => {
          this.error = "Konnte Update-Anfrage nicht senden.";
        });
    },

    // ---------- Delete ----------
    openDelete(ch) {
      this.deleteTarget = ch;
      this.showDeleteModal = true;
      this.error = null;
    },
    closeDeleteModal() {
      this.showDeleteModal = false;
      this.deleteTarget = null;
    },
    confirmDelete() {
      if (!this.deleteTarget || !this.deleteTarget.id) {
        this.error = "Ungültiger Löschvorgang.";
        return;
      }

      const payload = { id: this.deleteTarget.id };

      fetch(`https://${this.getResName()}/LCV:ADMIN:Characters:Delete`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(payload),
      })
        .then((res) => res.json())
        .then((data) => {
          if (!data || !data.ok) {
            this.error =
              (data && data.error) || "Fehler beim Löschen des Characters.";
            return;
          }

          this.characters = this.characters.filter(
            (c) => c.id !== this.deleteTarget.id
          );
          this.showDeleteModal = false;
          this.deleteTarget = null;
          this.error = null;
        })
        .catch(() => {
          this.error = "Konnte Delete-Anfrage nicht senden.";
        });
    },

    // ---------- Dummy-Actions ----------
    dummyRename(ch) {
      console.log("[ADMIN][CHAR] Dummy Name ändern für", ch.id, ch.name);
      alert("Name ändern ist noch nicht implementiert. (Kommt später.)");
    },

    lockCharacter(ch) {
      if (!ch || !ch.id) return;
      if (ch.is_locked) {
        alert("Dieser Character ist bereits gesperrt (Ausgereist).");
        return;
      }

      const payload = {
        id: ch.id,
        is_locked: true,
        residence_permit: ch.residence_permit ? 1 : 0,
      };

      fetch(`https://${this.getResName()}/LCV:ADMIN:Characters:Update`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(payload),
      })
        .then((res) => res.json())
        .then((data) => {
          if (!data || !data.ok) {
            this.error =
              (data && data.error) || "Fehler beim Sperren des Characters.";
            return;
          }

          const row = data.row;
          if (row) {
            const idx = this.characters.findIndex((c) => c.id === row.id);
            if (idx !== -1) {
              this.$set(this.characters, idx, row);
            }
          }

          this.error = null;
        })
        .catch(() => {
          this.error = "Konnte Sperr-Anfrage nicht senden.";
        });
    },
  },

  computed: {
    sortedCharacters() {
      let list = this.characters.slice();

      // Suche
      if (this.searchTerm) {
        const term = this.searchTerm.toLowerCase();
        list = list.filter((ch) => {
          const status = this.getStatusLabel(ch).toLowerCase();
          const online = this.getOnlineLabel(ch).toLowerCase();
          return (
            String(ch.id || "").includes(term) ||
            String(ch.account_id || "").includes(term) ||
            String(ch.name || "")
              .toLowerCase()
              .includes(term) ||
            String(ch.type || "")
              .toLowerCase()
              .includes(term) ||
            status.includes(term) ||
            online.includes(term)
          );
        });
      }

      // Sortierung
      const dir = this.sortDir === "asc" ? 1 : -1;

      list.sort((a, b) => {
        let va, vb;

        switch (this.sortKey) {
          case "account_id":
            va = Number(a.account_id) || 0;
            vb = Number(b.account_id) || 0;
            break;
          case "name":
            va = (a.name || "").toLowerCase();
            vb = (b.name || "").toLowerCase();
            break;
          case "type":
            va = String(a.type || "").toLowerCase();
            vb = String(b.type || "").toLowerCase();
            break;
          case "status":
            va = this.getStatusLabel(a).toLowerCase();
            vb = this.getStatusLabel(b).toLowerCase();
            break;
          case "online":
            va = a.online ? 1 : 0;
            vb = b.online ? 1 : 0;
            break;
          default: // id
            va = Number(a.id) || 0;
            vb = Number(b.id) || 0;
            break;
        }

        if (va < vb) return -1 * dir;
        if (va > vb) return 1 * dir;
        return 0;
      });

      return list;
    },
  },

  template: `
    <div class="options">
      <div class="interaction-header">
        <h2>Characters</h2>
        <div class="header-buttons">
          <input
            v-model="searchTerm"
            class="search-input"
            type="text"
            placeholder="Suche: ID, Account, Name, Typ, Status, Online"
          />
          <button class="btn-refresh" @click="fetchCharacters">
            <i class="fa-solid fa-rotate"></i> Refresh
          </button>
        </div>
      </div>

      <p class="hint">
        Übersicht aller Characters. Sortierbare Spalten, Suchfeld, Status basierend auf
        <strong>is_locked</strong>, <strong>residence_permit</strong> und Online-Status.
      </p>

      <div class="table-wrapper">
        <table class="table-interactions">
          <thead>
            <tr>
              <th class="sortable" @click="setSort('id')">
                ID
                <span class="sort-indicator">{{ sortIcon('id') }}</span>
              </th>
              <th class="sortable" @click="setSort('account_id')">
                Account
                <span class="sort-indicator">{{ sortIcon('account_id') }}</span>
              </th>
              <th class="sortable" @click="setSort('name')">
                Name
                <span class="sort-indicator">{{ sortIcon('name') }}</span>
              </th>
              <th>Level</th>
              <th>Geburtstag</th>
              <th class="sortable" @click="setSort('type')">
                Typ
                <span class="sort-indicator">{{ sortIcon('type') }}</span>
              </th>
              <th class="sortable" @click="setSort('status')">
                Status
                <span class="sort-indicator">{{ sortIcon('status') }}</span>
              </th>
              <th class="sortable" @click="setSort('online')">
                Online
                <span class="sort-indicator">{{ sortIcon('online') }}</span>
              </th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="9">Lade Characters…</td>
            </tr>
            <tr v-else-if="!sortedCharacters.length">
              <td colspan="9">Keine Characters gefunden.</td>
            </tr>
            <tr v-for="ch in sortedCharacters" :key="ch.id">
              <td>{{ ch.id }}</td>
              <td>{{ ch.account_id }}</td>
              <td>{{ ch.name }}</td>
              <td>{{ ch.level }}</td>
              <td>{{ formatBirthdate(ch) }}</td>
              <td>{{ ch.type }}</td>
              <td>
                <span :class="getStatusClass(ch)">
                  {{ getStatusLabel(ch) }}
                </span>
              </td>
              <td>
                <span :class="getOnlineClass(ch)">
                  {{ getOnlineLabel(ch) }}
                </span>
              </td>
              <td class="col-actions">
                <div class="actions">
                  <button
                    class="btn-icon"
                    title="Bearbeiten"
                    @click="openEdit(ch)"
                  >
                    <i class="fa-solid fa-pen"></i>
                  </button>
                  <button
                    class="btn-icon"
                    title="Name ändern (Dummy)"
                    @click="dummyRename(ch)"
                  >
                    <i class="fa-solid fa-signature"></i>
                  </button>
                  <button
                    class="btn-icon"
                    title="Sperren (is_locked = 1)"
                    @click="lockCharacter(ch)"
                  >
                    <i class="fa-solid fa-user-lock"></i>
                  </button>
                  <button
                    class="btn-icon danger"
                    title="Löschen"
                    @click="openDelete(ch)"
                  >
                    <i class="fa-solid fa-trash"></i>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Edit Modal -->
      <div v-if="showEditModal" class="modal-backdrop">
        <div class="modal">
          <h3>Character bearbeiten (#{{ editForm.id }})</h3>
          <label>Name (read-only aktuell)</label>
          <input type="text" v-model="editForm.name" disabled />

          <label>Level</label>
          <input type="number" v-model.number="editForm.level" min="0" />

          <label class="switch-label">
            <span>Sperren (is_locked)</span>
            <label class="switch">
              <input type="checkbox" v-model="editForm.is_locked" />
              <span class="slider round"></span>
            </label>
          </label>

          <label>Residence Permit</label>
          <select v-model.number="editForm.residence_permit">
            <option :value="0">0 - Nicht Eingereist</option>
            <option :value="1">1 - Eingereist</option>
          </select>

          <div class="modal-actions">
            <button class="btn" @click="saveCharacter">
              Speichern
            </button>
            <button class="btn secondary" @click="closeEditModal">
              Abbrechen
            </button>
          </div>

          <p v-if="error" class="error">{{ error }}</p>
        </div>
      </div>

      <!-- Delete Modal -->
      <div v-if="showDeleteModal" class="modal-backdrop">
        <div class="modal">
          <h3>Character löschen</h3>
          <p>
            Willst du den Character
            <strong v-if="deleteTarget">{{ deleteTarget.name }}</strong>
            wirklich löschen?
          </p>
          <div class="modal-actions">
            <button class="btn danger" @click="confirmDelete">
              Ja, löschen
            </button>
            <button class="btn secondary" @click="closeDeleteModal">
              Abbrechen
            </button>
          </div>
          <p v-if="error" class="error">{{ error }}</p>
        </div>
      </div>

      <p v-if="error && !showEditModal && !showDeleteModal" class="error">
        {{ error }}
      </p>
    </div>
  `,
});
