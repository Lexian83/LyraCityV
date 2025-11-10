Vue.component("lspd-personen", {
  props: ["identity"],
  data() {
    return {
      query: "",
      results: [],
      loading: false,
      error: null,

      showModal: false,
      isEdit: false,
      expandedId: null,

      form: {
        id: null,
        first_name: "",
        last_name: "",
        date_of_birth: "",
        gender: "",
        phone_number: "",
        address: "",
        driver_license: false,
        weapon_license: false,
        pilot_license: false,
        boat_license: false,
        is_dead: false,
        is_wanted: false,
        is_exited: false,
        danger_level: 0,
        notes: "",
      },
    };
  },

  created() {
    window.addEventListener("message", (event) => {
      const msg = event.data;
      if (!msg || !msg.action) return;

      if (msg.action === "lspd:searchPersonResult") {
        const payload = msg.data || {};
        this.loading = false;

        if (!payload.ok) {
          this.error = payload.reason || "Unbekannter Fehler bei der Suche.";
          this.results = [];
          return;
        }

        this.error = null;
        this.results = payload.rows || [];
      }

      if (msg.action === "lspd:createPersonResult") {
        const payload = msg.data || {};
        if (!payload.ok) {
          this.error = payload.reason || "Fehler beim Anlegen der Person.";
          return;
        }

        this.error = null;
        this.showModal = false;
        if (payload.row) this.upsertResult(payload.row);
      }

      if (msg.action === "lspd:updatePersonResult") {
        const payload = msg.data || {};
        if (!payload.ok) {
          this.error = payload.reason || "Fehler beim Bearbeiten der Person.";
          return;
        }

        this.error = null;
        this.showModal = false;
        if (payload.row) this.upsertResult(payload.row);
      }
    });
  },

  methods: {
    getResName() {
      if (typeof GetParentResourceName === "function") {
        return GetParentResourceName();
      }
      return "computer"; // ggf. anpassen auf deinen Resourcen-Namen
    },

    // Suche
    sendSearch() {
      const query =
        this.query && this.query.trim().length >= 2 ? this.query : "";

      this.loading = true;
      this.error = null;
      this.results = [];

      fetch(`https://${this.getResName()}/lspd_searchPerson`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({ query }),
      }).catch(() => {
        this.loading = false;
        this.error = "Konnte Anfrage nicht senden.";
      });
    },

    // Tabellenanzeige: Anrede + Name
    formatDisplayName(p) {
      if (p.gender === "m") return `Herr ${p.last_name}`;
      if (p.gender === "f") return `Frau ${p.last_name}`;
      // divers / unbekannt → voller Name
      return `${p.first_name} ${p.last_name}`;
    },

    // Statusanzeige
    formatStatus(p) {
      if (p.is_dead) return "Verstorben";
      if (p.is_wanted) return "Gesucht";
      if (p.is_exited) return "Ausgereist";
      return "Normal";
    },
    statusClass(p) {
      if (p.is_dead) return "status-badge status-dead";
      if (p.is_wanted) return "status-badge status-wanted";
      if (p.is_exited) return "status-badge status-exited";
      return "status-badge status-normal";
    },

    // Gefährdungs-Bubbles
    getDangerBubbleClass(level, index) {
      level = Number(level) || 0;
      if (index <= level) {
        if (level <= 2) return "filled-low";
        if (level <= 4) return "filled-mid";
        return "filled-high";
      }
      return "empty";
    },

    // Liste aktualisieren
    upsertResult(row) {
      const idx = this.results.findIndex((r) => r.id === row.id);
      if (idx !== -1) {
        this.$set(this.results, idx, row);
      } else {
        this.results.push(row);
      }
    },

    // Expand / Collapse
    toggleExpand(p) {
      this.expandedId = this.expandedId === p.id ? null : p.id;
    },

    // Modal
    openCreate() {
      this.isEdit = false;
      this.error = null;
      this.showModal = true;
      this.form = {
        id: null,
        first_name: "",
        last_name: "",
        date_of_birth: "",
        gender: "",
        phone_number: "",
        address: "",
        driver_license: false,
        weapon_license: false,
        pilot_license: false,
        boat_license: false,
        is_dead: false,
        is_wanted: false,
        is_exited: false,
        danger_level: 0,
        notes: "",
      };
    },

    openEdit(p) {
      this.isEdit = true;
      this.error = null;
      this.showModal = true;

      this.form = {
        id: p.id,
        first_name: p.first_name || "",
        last_name: p.last_name || "",
        // hier: bevorzugt das vom Server vorbereitete ISO-Datum
        date_of_birth: p.date_iso || p.date_of_birth || "",
        gender: p.gender || "",
        phone_number: p.phone_number || "",
        address: p.address || "",
        driver_license: !!p.driver_license,
        weapon_license: !!p.weapon_license,
        pilot_license: !!p.pilot_license,
        boat_license: !!p.boat_license,
        is_dead: !!p.is_dead,
        is_wanted: !!p.is_wanted,
        is_exited: !!p.is_exited,
        danger_level: Number(p.danger_level) || 0,
        notes: p.notes || "",
      };
    },

    closeModal() {
      this.showModal = false;
      this.error = null;
    },

    // Speichern
    submitForm() {
      if (
        !this.form.first_name ||
        !this.form.last_name ||
        !this.form.date_of_birth
      ) {
        this.error = "Vorname, Nachname und Geburtsdatum sind Pflichtfelder.";
        return;
      }

      const payload = {
        id: this.form.id,
        first_name: this.form.first_name,
        last_name: this.form.last_name,
        date_of_birth: this.form.date_of_birth,
        gender: this.form.gender || null,
        phone_number: this.form.phone_number,
        address: this.form.address,
        driver_license: !!this.form.driver_license,
        weapon_license: !!this.form.weapon_license,
        pilot_license: !!this.form.pilot_license,
        boat_license: !!this.form.boat_license,
        is_dead: !!this.form.is_dead,
        is_wanted: !!this.form.is_wanted,
        is_exited: !!this.form.is_exited,
        danger_level: Number(this.form.danger_level) || 0,
        notes: this.form.notes,
      };

      const route = this.isEdit ? "lspd_updatePerson" : "lspd_createPerson";

      fetch(`https://${this.getResName()}/${route}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(payload),
      }).catch(() => {
        this.error = "Konnte Anfrage nicht senden.";
      });
    },
  },
  mounted() {
    // automatisch alle Einträge laden
    this.sendSearch();
  },

  template: `
    <div class="lspd-persons">
      <div class="header-row">
        <h2>Personenabfrage</h2>
        <button class="btn-small" @click="openCreate">Neue Person anlegen</button>
      </div>

      <div class="search-row">
        <input
          v-model="query"
          type="text"
          placeholder="Suche nach Name, Kombination oder Telefonnummer..."
          @keyup.enter="sendSearch"
        />
        <button @click="sendSearch">Suchen</button>
      </div>

      <div v-if="loading" class="info">Suche läuft...</div>
      <div v-if="error" class="error">{{ error }}</div>

      <table v-if="!loading && results.length" class="person-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Geburtsdatum</th>
            <th>Telefon</th>
            <th>Status</th>
            <th>Gefährdung</th>
            <th class="th-actions">Aktionen</th>
          </tr>
        </thead>
        <tbody class="row-persons">
          <template v-for="p in results" :key="p.id">
            <tr>
              <td>{{ formatDisplayName(p) }}</td>
              <td>{{ p.dob || '-' }}</td>
              <td>{{ p.phone_number || '-' }}</td>
              <td><span :class="statusClass(p)">{{ formatStatus(p) }}</span></td>
              <td>
                <div class="danger-bubbles">
                  <span
                    v-for="i in 5"
                    :key="i"
                    class="danger-bubble"
                    :class="getDangerBubbleClass(p.danger_level, i)"
                  ></span>
                </div>
              </td>
              <td class="row-actions">
                <button class="link-btn" @click="openEdit(p)"><i class="fa-solid fa-pen"></i></button>
                <button class="link-btn akten-btn"><i class="fa-solid fa-folder"></i></button>
                <button class="arrow-btn" @click="toggleExpand(p)">
                  <span :class="{ 'arrow-open': expandedId === p.id }">▾</span>
                </button>
              </td>
            </tr>

            <!-- Expandierte Detailzeile -->
            <tr v-if="expandedId === p.id" class="expand-row">
              <td colspan="6">
                <div class="expand-content">
                  <div class="expand-col">
                    <div><strong>Voller Name:</strong> {{ p.first_name }} {{ p.last_name }}</div>
                    <div><strong>Geburtsdatum:</strong> {{ p.dob || '-' }}</div>
                    <div><strong>Geschlecht:</strong>
                      <span v-if="p.gender === 'm'">Männlich</span>
                      <span v-else-if="p.gender === 'f'">Weiblich</span>
                      <span v-else-if="p.gender === 'd'">Divers</span>
                      <span v-else>-</span>
                    </div>
                    <div><strong>Telefon:</strong> {{ p.phone_number || '-' }}</div>
                    <div><strong>Adresse:</strong> {{ p.address || '-' }}</div>
                  </div>
                  <div class="expand-col">
                    <div><strong>Dokumente:</strong></div>
                    <div>Führerschein: {{ p.driver_license ? 'Ja' : 'Nein' }}</div>
                    <div>Waffenschein: {{ p.weapon_license ? 'Ja' : 'Nein' }}</div>
                    <div>Pilotenschein: {{ p.pilot_license ? 'Ja' : 'Nein' }}</div>
                    <div>Bootsführerschein: {{ p.boat_license ? 'Ja' : 'Nein' }}</div>
                    <div style="margin-top:4px;"><strong>Status:</strong> {{ formatStatus(p) }}</div>
                    <div><strong>Gefährdung:</strong> {{ p.danger_level || 0 }} / 5</div>
                  </div>
                  <div class="expand-col">
                    <div><strong>Notizen:</strong></div>
                    <div class="notes-expand">
                      {{ p.notes && p.notes.length ? p.notes : 'Keine Notizen hinterlegt.' }}
                    </div>
                  </div>
                </div>
              </td>
            </tr>
          </template>
        </tbody>
      </table>

      <div v-if="!loading && !results.length && !error" class="info">
        Keine Ergebnisse gefunden.
      </div>

      <!-- Modal -->
      <div v-if="showModal" class="lspd-modal-overlay">
        <div class="lspd-modal">
          <div class="modal-header">
            <h3>{{ isEdit ? 'Person bearbeiten' : 'Person anlegen' }}</h3>
            <button class="modal-close" @click="closeModal">×</button>
          </div>

          <div class="modal-body">
            <div class="modal-grid-2col">
              <!-- Linke Spalte: Eingaben mit Placeholder -->
              <div class="modal-col">
                <input v-model="form.first_name" type="text" placeholder="Vorname*" />
                <input v-model="form.last_name" type="text" placeholder="Nachname*" />
                <input v-model="form.date_of_birth" type="date" />
                <select v-model="form.gender">
                  <option disabled value="">Geschlecht wählen</option>
                  <option value="m">Männlich</option>
                  <option value="f">Weiblich</option>
                  <option value="d">Divers</option>
                </select>
                <input v-model="form.phone_number" type="text" placeholder="Telefon" />
                <input v-model="form.address" type="text" placeholder="Adresse" />
                <input
                  v-model.number="form.danger_level"
                  type="number"
                  min="0"
                  max="5"
                  placeholder="Gefährdungsstufe (0-5)"
                />
              </div>

              <!-- Rechte Spalte: Flags -->
              <div class="modal-col flags-col">
                <div class="flags-title">Dokumente</div>
                <label><input type="checkbox" v-model="form.driver_license" /> Führerschein</label>
                <label><input type="checkbox" v-model="form.weapon_license" /> Waffenschein</label>
                <label><input type="checkbox" v-model="form.pilot_license" /> Pilotenschein</label>
                <label><input type="checkbox" v-model="form.boat_license" /> Bootsführerschein</label>

                <div class="flags-title" style="margin-top:8px;">Status</div>
                <label><input type="checkbox" v-model="form.is_dead" /> Verstorben</label>
                <label><input type="checkbox" v-model="form.is_wanted" /> Gesucht</label>
                <label><input type="checkbox" v-model="form.is_exited" /> Ausgereist</label>
              </div>
            </div>

            <textarea
              v-model="form.notes"
              class="notes-textarea"
              rows="4"
              placeholder="Notizen / Hinweise"
            ></textarea>

            <div v-if="error" class="error" style="margin-top:4px">
              {{ error }}
            </div>
          </div>

          <div class="modal-footer">
            <button class="btn-flat btn-cancel" @click="closeModal">
              Abbrechen
            </button>
            <button class="btn-flat btn-primary" @click="submitForm">
              {{ isEdit ? 'Speichern' : 'Anlegen' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
});
