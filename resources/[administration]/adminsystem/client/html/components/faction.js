Vue.component("tab-faction", {
  props: ["identity"],
  data() {
    return {
      query: "",
      factions: [],
      loading: false,
      error: null,

      expandedId: null,

      characters: [],
      charLoading: false,

      // key -> { label, factions? }
      permissionSchema: {},

      showModal: false,
      isEdit: false,
      formError: null,
      form: {
        id: null,
        name: "",
        label: "",
        leader_char_id: null,
        description: "",
        duty_required: false,
        is_gang: false,
      },

      showDeleteModal: false,
      deleteTarget: null,
      deleteError: null,

      // pro factionId:
      // { loading, error, members, ranks, logs, newMemberCharId, newMemberRankId, newRankName, newRankLevel }
      details: {},
    };
  },

  methods: {
    getResName() {
      return typeof GetParentResourceName === "function"
        ? GetParentResourceName()
        : "admin-menu";
    },

    // ---------- Utils ----------
    formatDate(val) {
      if (!val) return "-";
      if (typeof val === "number") {
        const ms = val > 1000000000000 ? val : val * 1000;
        return new Date(ms).toLocaleString();
      }
      const d = new Date(val);
      if (!isNaN(d.getTime())) return d.toLocaleString();
      return String(val);
    },

    formatLeader(f) {
      if (f.leader_name) return f.leader_name;
      if (f.leader_char_id) return "CID " + f.leader_char_id;
      return "-";
    },

    formatMembersCount(f) {
      const c = Number(f.member_count) || 0;
      if (c === 0) return "keine";
      if (c === 1) return "1 Mitglied";
      return c + " Mitglieder";
    },

    getCharLabel(id) {
      const c = this.characters.find((x) => x.id === id);
      return c ? c.label : id ? "CID " + id : "-";
    },

    normalizePermissions(raw) {
      if (typeof raw === "string") {
        try {
          raw = JSON.parse(raw);
        } catch (e) {
          raw = {};
        }
      }
      if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
        raw = {};
      }
      return raw;
    },

    // Sichtbarkeit einer Permission für eine bestimmte Fraktion
    isPermissionAllowedForFaction(perm, faction) {
      if (!perm || !faction) return true;

      const cfg = perm.factions;
      if (!cfg) return true; // keine Einschränkung

      const name = faction.name;
      const id = faction.id;

      if (Array.isArray(cfg)) {
        if (cfg.includes(name) || cfg.includes(id)) return true;
        return false;
      }

      if (typeof cfg === "object") {
        if (cfg[name] || cfg[id]) return true;
        return false;
      }

      return true;
    },

    // ---------- Permission Schema ----------
    async loadPermissionSchema() {
      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Factions:GetPermissionSchema`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify({}),
          }
        );
        const data = await res.json();
        if (data && data.ok && data.schema) {
          this.permissionSchema = data.schema;
        } else {
          this.permissionSchema = this.permissionSchemaFallback();
        }
      } catch (e) {
        this.permissionSchema = this.permissionSchemaFallback();
      }
    },

    permissionSchemaFallback() {
      return {
        manage_faction: { label: "Fraktion bearbeiten" },
        manage_ranks: { label: "Ränge verwalten" },
        invite: { label: "Mitglieder einladen" },
        kick: { label: "Mitglieder entfernen" },
        set_rank: { label: "Rang zuweisen" },
        view_logs: { label: "Logs einsehen" },
      };
    },

    // ---------- Load Basics ----------
    async loadFactions() {
      this.loading = true;
      this.error = null;

      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Factions:GetAll`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify({ query: this.query || "" }),
          }
        );
        const data = await res.json();
        if (!data || !data.ok) {
          this.error = (data && data.error) || "Fehler beim Laden.";
          this.factions = [];
        } else {
          this.factions = data.factions || [];
        }
      } catch (e) {
        this.error = "Konnte Factions nicht laden.";
        this.factions = [];
      }

      this.loading = false;
    },

    async loadCharactersOnce() {
      if (this.characters.length || this.charLoading) return;
      this.charLoading = true;
      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Factions:GetCharactersSimple`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify({}),
          }
        );
        const data = await res.json();
        if (data && data.ok && Array.isArray(data.characters)) {
          this.characters = data.characters;
        }
      } catch (e) {}
      this.charLoading = false;
    },

    // ---------- Expand & Details ----------
    async toggleExpand(f) {
      if (this.expandedId === f.id) {
        this.expandedId = null;
        return;
      }
      this.expandedId = f.id;
      await this.ensureDetails(f.id);
    },

    async ensureDetails(factionId) {
      if (!factionId) return;

      if (!this.details[factionId]) {
        this.$set(this.details, factionId, {
          loading: false,
          error: null,
          members: [],
          ranks: [],
          logs: [],
          newMemberCharId: null,
          newMemberRankId: null,
          newRankName: "",
          newRankLevel: 1,
        });
      }

      const d = this.details[factionId];
      d.loading = true;
      d.error = null;

      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Factions:GetDetails`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify({ id: factionId }),
          }
        );
        const data = await res.json();
        if (!data || !data.ok) {
          d.error = (data && data.error) || "Fehler beim Laden der Details.";
        } else {
          d.members = data.members || [];
          d.ranks = (data.ranks || []).map((r) => {
            r.permissions = this.normalizePermissions(r.permissions);
            r._editName = r.name;
            r._editLevel = Number(r.level) || 1;
            return r;
          });
          d.logs = data.logs || [];
        }
      } catch (e) {
        d.error = "Konnte Details nicht laden.";
      }

      d.loading = false;
    },

    // ---------- Faction Modal ----------
    openCreate() {
      this.isEdit = false;
      this.formError = null;
      this.showModal = true;
      this.loadCharactersOnce();
      this.form = {
        id: null,
        name: "",
        label: "",
        leader_char_id: null,
        description: "",
        duty_required: false,
        is_gang: false,
      };
    },

    openEdit(f) {
      this.isEdit = true;
      this.formError = null;
      this.showModal = true;
      this.loadCharactersOnce();

      this.form = {
        id: f.id,
        name: f.name || "",
        label: f.label || "",
        leader_char_id: f.leader_char_id || null,
        description: f.description || "",
        duty_required: Number(f.duty_required) === 1,
        is_gang: Number(f.is_gang) === 1,
      };
    },

    closeModal() {
      this.showModal = false;
      this.formError = null;
    },

    async submitForm() {
      if (!this.form.name || !this.form.name.trim()) {
        this.formError = "Fraktionsname (Key) ist Pflicht.";
        return;
      }

      const payload = {
        id: this.form.id,
        name: this.form.name.trim(),
        label: this.form.label && this.form.label.trim(),
        leader_char_id: this.form.leader_char_id || null,
        description: this.form.description || "",
        duty_required: !!this.form.duty_required,
        is_gang: !!this.form.is_gang,
      };

      const route = this.isEdit
        ? "LCV:ADMIN:Factions:Update"
        : "LCV:ADMIN:Factions:Create";

      try {
        const res = await fetch(`https://${this.getResName()}/${route}`, {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify(payload),
        });
        const data = await res.json();
        if (!data || !data.ok) {
          this.formError = (data && data.error) || "Fehler beim Speichern.";
          return;
        }

        await this.loadFactions();
        this.showModal = false;
      } catch (e) {
        this.formError = "Konnte Anfrage nicht senden.";
      }
    },

    // ---------- Delete ----------
    confirmDelete(f) {
      this.deleteTarget = f;
      this.deleteError = null;
      this.showDeleteModal = true;
    },

    cancelDelete() {
      this.showDeleteModal = false;
      this.deleteTarget = null;
      this.deleteError = null;
    },

    async doDelete() {
      if (!this.deleteTarget) return;

      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Factions:Delete`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify({ id: this.deleteTarget.id }),
          }
        );
        const data = await res.json();
        if (!data || !data.ok) {
          this.deleteError = (data && data.error) || "Fehler beim Löschen.";
          return;
        }

        this.factions = this.factions.filter(
          (x) => x.id !== this.deleteTarget.id
        );
        this.expandedId = null;
        this.showDeleteModal = false;
      } catch (e) {
        this.deleteError = "Konnte Anfrage nicht senden.";
      }
    },

    // ---------- Member Management ----------
    async addMember(factionId) {
      const d = this.details[factionId];
      if (!d || !d.newMemberCharId || !d.newMemberRankId) return;

      const payload = {
        faction_id: factionId,
        char_id: Number(d.newMemberCharId),
        rank_id: Number(d.newMemberRankId),
      };

      const res = await fetch(
        `https://${this.getResName()}/LCV:ADMIN:Factions:AddMember`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify(payload),
        }
      );
      const data = await res.json();
      if (data && data.ok) {
        d.members = data.members || [];
        d.newMemberCharId = null;
        d.newMemberRankId = null;
      } else {
        d.error = (data && data.error) || "Fehler beim Hinzufügen.";
      }
    },

    async setMemberRank(factionId, m, rankId) {
      const d = this.details[factionId];
      if (!d) return;

      const payload = {
        faction_id: factionId,
        char_id: m.char_id,
        rank_id: Number(rankId),
      };

      const res = await fetch(
        `https://${this.getResName()}/LCV:ADMIN:Factions:SetMemberRank`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify(payload),
        }
      );
      const data = await res.json();
      if (data && data.ok) {
        d.members = data.members || [];
      } else {
        d.error =
          (data && data.error) || "Fehler beim Aktualisieren des Rangs.";
      }
    },

    async removeMember(factionId, m) {
      const d = this.details[factionId];
      if (!d) return;

      const res = await fetch(
        `https://${this.getResName()}/LCV:ADMIN:Factions:RemoveMember`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify({
            faction_id: factionId,
            char_id: m.char_id,
          }),
        }
      );
      const data = await res.json();
      if (data && data.ok) {
        d.members = data.members || [];
      } else {
        d.error = (data && data.error) || "Fehler beim Entfernen.";
      }
    },

    // ---------- Rank Management ----------
    async createRank(factionId) {
      const d = this.details[factionId];
      if (!d || !d.newRankName) return;

      const res = await fetch(
        `https://${this.getResName()}/LCV:ADMIN:Factions:CreateRank`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify({
            faction_id: factionId,
            name: d.newRankName,
            level: Number(d.newRankLevel) || 1,
          }),
        }
      );
      const data = await res.json();
      if (data && data.ok) {
        d.ranks = (data.ranks || []).map((r) => {
          r.permissions = this.normalizePermissions(r.permissions);
          r._editName = r.name;
          r._editLevel = Number(r.level) || 1;
          return r;
        });
        d.newRankName = "";
        d.newRankLevel = 1;
      } else {
        d.error = (data && data.error) || "Fehler beim Anlegen des Rangs.";
      }
    },

    async deleteRank(factionId, rank) {
      const d = this.details[factionId];
      if (!d) return;

      const res = await fetch(
        `https://${this.getResName()}/LCV:ADMIN:Factions:DeleteRank`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json; charset=UTF-8" },
          body: JSON.stringify({
            id: rank.id,
            faction_id: factionId,
          }),
        }
      );
      const data = await res.json();
      if (data && data.ok) {
        d.ranks = (data.ranks || []).map((r) => {
          r.permissions = this.normalizePermissions(r.permissions);
          r._editName = r.name;
          r._editLevel = Number(r.level) || 1;
          return r;
        });
      } else {
        d.error =
          (data && data.error) ||
          "Fehler beim Löschen des Rangs (evtl. in Benutzung).";
      }
    },

    saveRank(factionId, r) {
      r.permissions = this.normalizePermissions(r.permissions);

      const payload = {
        id: r.id,
        faction_id: factionId,
        name: r._editName || r.name,
        level: r._editLevel || r.level,
        permissions: r.permissions || {},
      };

      fetch(`https://${this.getResName()}/LCV:ADMIN:Factions:UpdateRank`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(payload),
      })
        .then((res) => res.json())
        .then((data) => {
          if (data && data.ok && data.ranks) {
            this.details[factionId].ranks = (data.ranks || []).map((nr) => {
              nr.permissions = this.normalizePermissions(nr.permissions);
              nr._editName = nr.name;
              nr._editLevel = Number(nr.level) || 1;
              return nr;
            });
          } else if (data && data.error) {
            this.details[factionId].error = data.error;
          }
        })
        .catch(() => {
          this.details[factionId].error = "Konnte Rang nicht speichern.";
        });
    },

    toggleRankPerm(factionId, r, key, enabled) {
      r.permissions = this.normalizePermissions(r.permissions);
      this.$set(r.permissions, key, !!enabled);
      this.saveRank(factionId, r);
    },
  },

  mounted() {
    this.loadPermissionSchema();
    this.loadFactions();
    this.loadCharactersOnce();
  },

  template: `
    <div class="options">
      <div class="interaction-header">
        <div>
          <h2 style="margin:0; font-size:14px;">Fraktions Manager</h2>
          <p class="hint">Zentrale Verwaltung für LSPD, LSMD, Gangs & Co. (factionManager).</p>
        </div>
        <div class="header-buttons">
          <button class="add-btn" @click="openCreate">
            <i class="fa fa-plus"></i> Neue Fraktion
          </button>
          <button class="refresh-btn" @click="loadFactions">
            <i class="fa fa-rotate"></i>
          </button>
        </div>
      </div>

      <div class="search-row">
        <input
          v-model="query"
          type="text"
          placeholder="Suche nach Name / Label..."
          @keyup.enter="loadFactions"
        />
        <button class="pos-btn" @click="loadFactions">
          <i class="fa fa-search"></i>
        </button>
      </div>

      <div v-if="loading" class="status">Lade Fraktionen...</div>
      <div v-if="error" class="status error">{{ error }}</div>

      <div v-if="!loading" class="table-wrapper">
        <table class="table-interactions" v-if="factions.length">
          <thead>
            <tr>
              <th style="width:26px;"></th>
              <th>ID</th>
              <th>Name (Key)</th>
              <th>Label</th>
              <th>Leader</th>
              <th>Mitglieder</th>
              <th>Duty</th>
              <th>Gang</th>
              <th>Erstellt am</th>
              <th class="col-actions">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            <template v-for="f in factions" :key="f.id">
              <tr>
                <td>
                  <button class="btn-icon" @click="toggleExpand(f)">
                    <i :class="expandedId === f.id ? 'fa fa-chevron-up' : 'fa fa-chevron-down'"></i>
                  </button>
                </td>
                <td>{{ f.id }}</td>
                <td>{{ f.name }}</td>
                <td>{{ f.label || '-' }}</td>
                <td>{{ formatLeader(f) }}</td>
                <td>{{ formatMembersCount(f) }}</td>
                <td>{{ Number(f.duty_required) === 1 ? 'Ja' : '-' }}</td>
                <td>{{ Number(f.is_gang) === 1 ? 'Ja' : '-' }}</td>
                <td>{{ formatDate(f.created_at) }}</td>
                <td class="col-actions">
                  <button class="btn-icon" @click="openEdit(f)">
                    <i class="fa fa-pen"></i>
                  </button>
                  <button class="btn-icon danger" @click="confirmDelete(f)">
                    <i class="fa fa-trash"></i>
                  </button>
                </td>
              </tr>

              <!-- EXPANDED DETAILS (wie gehabt, unverändert außer Text oben) -->
              <tr v-if="expandedId === f.id">
                <td colspan="10">
                  <div class="faction-details" v-if="details[f.id]">
                    <div v-if="details[f.id].loading" class="status">Lade Details...</div>
                    <div v-else>
                      <div v-if="details[f.id].error" class="status error">
                        {{ details[f.id].error }}
                      </div>
                      <div class="faction-columns">
                        <!-- LEFT: MEMBERS -->
                        <div class="faction-col">
                          <h4>Mitglieder</h4>
                          <div class="faction-sub-row">
                            <select v-model="details[f.id].newMemberCharId">
                              <option disabled value="">Char auswählen...</option>
                              <option
                                v-for="c in characters"
                                :key="c.id"
                                :value="c.id"
                              >{{ c.label }}</option>
                            </select>
                            <select v-model="details[f.id].newMemberRankId">
                              <option disabled value="">Rang</option>
                              <option
                                v-for="r in details[f.id].ranks"
                                :key="r.id"
                                :value="r.id"
                              >
                                {{ r.name }} ({{ r.level }})
                              </option>
                            </select>
                            <button class="mini-btn" @click="addMember(f.id)">
                              Hinzufügen
                            </button>
                          </div>
                          <ul class="mini-list">
                            <li v-for="m in details[f.id].members" :key="m.id">
                              <div class="mini-row">
                                <div class="mini-main">
                                  <div class="mini-title">
                                    {{ m.char_name || ('CID ' + m.char_id) }}
                                  </div>
                                  <div class="mini-sub">
                                    Rang:
                                    <select
                                      :value="m.rank_id"
                                      @change="setMemberRank(f.id, m, $event.target.value)"
                                    >
                                      <option
                                        v-for="r in details[f.id].ranks"
                                        :key="r.id"
                                        :value="r.id"
                                      >
                                        {{ r.name }} ({{ r.level }})
                                      </option>
                                    </select>
                                  </div>
                                </div>
                                <button class="mini-btn danger" @click="removeMember(f.id, m)">
                                  <i class="fa fa-xmark"></i>
                                </button>
                              </div>
                            </li>
                          </ul>
                        </div>

                        <!-- MIDDLE: RÄNGE -->
                        <div class="faction-col">
                          <h4>Ränge & Rechte</h4>
                          <div class="faction-sub-row">
                            <input
                              v-model="details[f.id].newRankName"
                              type="text"
                              placeholder="Neuer Rangname"
                            />
                            <input
                              v-model.number="details[f.id].newRankLevel"
                              type="number"
                              min="1"
                              max="255"
                              placeholder="Lvl"
                            />
                            <button class="mini-btn" @click="createRank(f.id)">
                              +
                            </button>
                          </div>
                          <ul class="mini-list">
                            <li v-for="r in details[f.id].ranks" :key="r.id">
                              <div class="mini-row">
                                <div class="mini-main">
                                  <div class="mini-title">
                                    <input
                                      v-model="r._editName"
                                      type="text"
                                      class="rank-input"
                                      :placeholder="r.name"
                                    />
                                    <span class="tag">
                                      Lvl
                                      <input
                                        v-model.number="r._editLevel"
                                        type="number"
                                        min="1"
                                        max="255"
                                        class="rank-level-input"
                                      />
                                    </span>
                                  </div>
                                  <div class="perm-flags">
                                    <label
                                      v-for="(perm, key) in permissionSchema"
                                      :key="key"
                                      v-if="isPermissionAllowedForFaction(perm, f)"
                                    >
                                      <input
                                        type="checkbox"
                                        :checked="r.permissions && r.permissions[key]"
                                        @change="toggleRankPerm(f.id, r, key, $event.target.checked)"
                                      />
                                      {{ perm.label || key }}
                                    </label>
                                  </div>
                                </div>
                                <div class="mini-actions">
                                  <button class="mini-btn" @click="saveRank(f.id, r)">
                                    <i class="fa fa-save"></i>
                                  </button>
                                  <button
                                    class="mini-btn danger"
                                    @click="deleteRank(f.id, r)"
                                    title="Rang löschen"
                                  >
                                    <i class="fa fa-trash"></i>
                                  </button>
                                </div>
                              </div>
                            </li>
                          </ul>
                        </div>

                        <!-- RIGHT: LOGS -->
                        <div class="faction-col">
                          <h4>Logs</h4>
                          <ul class="logs-list">
                            <li v-for="log in details[f.id].logs" :key="log.id">
                              <div class="log-line">
                                <span class="log-time">{{ formatDate(log.created_at) }}</span>
                                <span class="log-text">
                                  [{{ log.action }}]
                                  <span v-if="log.actor_name"> {{ log.actor_name }} </span>
                                  <span v-else-if="log.actor_char_id">CID {{ log.actor_char_id }}</span>
                                  <span v-if="log.target_name"> → {{ log.target_name }}</span>
                                  <span v-else-if="log.target_char_id"> → CID {{ log.target_char_id }}</span>
                                </span>
                              </div>
                            </li>
                            <li v-if="!details[f.id].logs.length" class="log-empty">
                              Keine Einträge.
                            </li>
                          </ul>
                        </div>
                      </div>
                    </div>
                  </div>
                </td>
              </tr>
            </template>
          </tbody>
        </table>

        <div v-if="!factions.length && !error" class="status">
          Keine Fraktionen gefunden.
        </div>
      </div>

      <!-- MODAL: CREATE / EDIT -->
      <div v-if="showModal" class="modal-backdrop">
        <div class="modal">
          <div class="modal-header">
            <h3>{{ isEdit ? 'Fraktion bearbeiten' : 'Neue Fraktion anlegen' }}</h3>
            <button class="modal-close" @click="closeModal">×</button>
          </div>
          <div class="modal-body">
            <div class="modal-grid-2col">
              <div class="modal-col">
                <label>Name (Key)*</label>
                <input v-model="form.name" type="text" placeholder="z.B. LSPD" />

                <label>Label</label>
                <input
                  v-model="form.label"
                  type="text"
                  placeholder="Los Santos Police Department"
                />

                <label>
                  <input type="checkbox" v-model="form.duty_required" />
                  Duty benötigt (On-Duty System)
                </label>

                <label>
                  <input type="checkbox" v-model="form.is_gang" />
                  Gang / Illegale Organisation
                </label>
              </div>
              <div class="modal-col">
                <label>Leader</label>
                <select v-model="form.leader_char_id">
                  <option :value="null">Kein Leader</option>
                  <option
                    v-for="c in characters"
                    :key="c.id"
                    :value="c.id"
                  >
                    {{ c.label }}
                  </option>
                </select>

                <label>Beschreibung</label>
                <textarea
                  v-model="form.description"
                  rows="3"
                  placeholder="Kurzbeschreibung..."
                ></textarea>
              </div>
            </div>

            <div v-if="formError" class="modal-error">{{ formError }}</div>
          </div>
          <div class="modal-actions">
            <button class="modal-btn" @click="closeModal">Abbrechen</button>
            <button class="modal-btn primary" @click="submitForm">
              {{ isEdit ? 'Speichern' : 'Anlegen' }}
            </button>
          </div>
        </div>
      </div>

      <!-- DELETE CONFIRM -->
      <div v-if="showDeleteModal" class="modal-backdrop">
        <div class="modal">
          <h3>Fraktion löschen?</h3>
          <p>
            Soll die Fraktion
            <strong>{{ deleteTarget && deleteTarget.name }}</strong>
            wirklich gelöscht werden?
          </p>
          <p><small>Mitglieder-Verknüpfungen werden entfernt.</small></p>
          <div v-if="deleteError" class="modal-error">{{ deleteError }}</div>
          <div class="modal-actions">
            <button class="modal-btn" @click="cancelDelete">Abbrechen</button>
            <button class="modal-btn danger" @click="doDelete">Löschen</button>
          </div>
        </div>
      </div>
    </div>
  `,
});
