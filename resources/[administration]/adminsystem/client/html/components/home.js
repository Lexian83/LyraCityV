Vue.component("tab-home", {
  props: ["identity"],
  data() {
    return {
      // Quick Admin Toggles
      toggles: {
        noclip: false,
        godmode: false,
        invisible: false,
        nametags: false,
      },
      busy: {
        noclip: false,
        godmode: false,
        invisible: false,
        nametags: false,
      },
      error: null,

      // Duty UI
      dutyFactions: [], // Fraktionen (duty_required = 1), in denen der aktuelle Char Mitglied ist
      dutyCurrent: [], // Fraktionen, in denen dieser Char aktuell on duty ist
      dutySelected: "", // gewählte Faction-ID für Einstempeln/Ausstempeln
      dutyBusy: false,
      dutyError: null,
    };
  },

  methods: {
    getResName() {
      return typeof GetParentResourceName === "function"
        ? GetParentResourceName()
        : "adminsystem";
    },

    // ====== ADMIN TOGGLES ======
    async toggle(key) {
      if (this.busy[key]) return;

      this.busy[key] = true;
      this.error = null;

      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Toggle:${key}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify({ enabled: !this.toggles[key] }),
          }
        );

        let json = null;
        try {
          json = await res.json();
        } catch (e) {}

        if (!json || json.ok === false) {
          throw new Error((json && json.error) || "Unbekannter Fehler");
        }

        this.toggles[key] = !!json.state;
      } catch (e) {
        console.error("[ADMIN][HOME] Toggle error:", key, e);
        this.error = `Fehler bei ${key}: ${e.message || e}`;
      } finally {
        this.busy[key] = false;
      }
    },

    async syncState() {
      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Quick:GetState`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({}),
          }
        );
        const json = await res.json().catch(() => null);
        if (!json || !json.ok) return;

        this.toggles.noclip = !!json.noclip;
        this.toggles.godmode = !!json.godmode;
        this.toggles.invisible = !!json.invisible;
        this.toggles.nametags = !!json.nametags;
      } catch (e) {
        console.warn("[ADMIN][HOME] Konnte State nicht syncen:", e);
      }
    },

    // ====== PORT TO WAYPOINT ======
    async portToWaypoint() {
      this.error = null;
      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:PortToWaypoint`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({}),
          }
        );

        const json = await res.json().catch(() => null);

        if (!json || json.ok === false) {
          throw new Error((json && json.error) || "Teleport fehlgeschlagen");
        }
      } catch (e) {
        console.error("[ADMIN][HOME] PortToWaypoint error:", e);
        this.error = `Teleport fehlgeschlagen: ${e.message || e}`;
      }
    },

    // ====== DUTY: LADEN ======

    async syncDuty() {
      this.dutyError = null;

      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Home:GetDutyData`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({}),
          }
        );

        const json = await res.json().catch(() => null);

        if (!json || json.ok === false) {
          this.dutyFactions = [];
          this.dutyCurrent = [];
          if (json && json.error) this.dutyError = json.error;
          return;
        }

        this.dutyFactions = Array.isArray(json.dutyFactions)
          ? json.dutyFactions
          : [];
        this.dutyCurrent = Array.isArray(json.currentDuty)
          ? json.currentDuty
          : [];

        // Falls aktuelle Auswahl nicht mehr gültig ist -> zurücksetzen
        if (
          this.dutySelected &&
          !this.dutyFactions.some(
            (f) => String(f.id) === String(this.dutySelected)
          )
        ) {
          this.dutySelected = "";
        }

        // Autoselect, wenn nichts gewählt & genau eine Faction
        if (!this.dutySelected && this.dutyFactions.length === 1) {
          this.dutySelected = String(this.dutyFactions[0].id);
        }
      } catch (e) {
        console.error("[ADMIN][HOME] Duty Sync error:", e);
        this.dutyError = "Duty-Infos konnten nicht geladen werden.";
        this.dutyFactions = [];
        this.dutyCurrent = [];
      }
    },

    // ====== DUTY: SETZEN ======

    async setDuty(on) {
      if (!this.dutySelected || this.dutyBusy) return;

      this.dutyBusy = true;
      this.dutyError = null;

      try {
        const res = await fetch(
          `https://${this.getResName()}/LCV:ADMIN:Home:SetDuty`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({
              faction_id: Number(this.dutySelected),
              on: !!on,
            }),
          }
        );

        const json = await res.json().catch(() => null);

        if (!json || json.ok === false) {
          throw new Error(
            (json && json.error) || "Duty konnte nicht gesetzt werden."
          );
        }

        // Server sendet dutyFactions + currentDuty zurück → direkt übernehmen
        if (Array.isArray(json.dutyFactions)) {
          this.dutyFactions = json.dutyFactions;
        }

        this.dutyCurrent = Array.isArray(json.currentDuty)
          ? json.currentDuty
          : [];
      } catch (e) {
        console.error("[ADMIN][HOME] setDuty error:", e);
        this.dutyError = e.message || e;
      } finally {
        this.dutyBusy = false;
        // Sicherheitshalber alles neu holen
        this.syncDuty();
      }
    },
  },

  mounted() {
    this.syncState();
    this.syncDuty();

    window.addEventListener("message", (event) => {
      if (event.data && event.data.action === "openADMIN") {
        this.syncState();
        this.syncDuty();
      }
    });
  },

  template: `
    <div class="options">
      <div class="home-layout">
        <!-- LINKE SPALTE -->
        <div class="home-left">
          <h1 style="margin:0">Hallo 👋</h1>
          <p>
            Willkommen im LCV Admin Tablet.
            Links siehst du deinen aktuellen Duty-Status, rechts deine schnellen Admin-Tools.
          </p>

          <div class="duty-panel">
            <h3 style="margin:4px 0 6px;">Dein Duty Status</h3>

            <!-- Wenn keine aktuelle Duty-Fraktion -->
            <div v-if="dutyCurrent.length === 0" class="duty-row">
              <div class="duty-info">
                <div class="duty-label">Keine aktive Duty</div>
                <div class="duty-name">Du bist aktuell Off Duty.</div>
              </div>
              <div class="duty-status off">
                Off Duty
              </div>
            </div>

            <!-- Aktive Duty-Fraktionen -->
            <div
              v-for="f in dutyCurrent"
              :key="'curr-' + f.id"
              class="duty-row"
            >
              <div class="duty-info">
                <div class="duty-label">{{ f.label || f.name }}</div>
                <div class="duty-name">({{ f.name }})</div>
              </div>
              <div class="duty-status on">
                On Duty
              </div>
            </div>

            <div v-if="dutyError" class="status error" style="margin-top:6px;">
              {{ dutyError }}
            </div>
          </div>
        </div>

        <!-- RECHTE SPALTE -->
        <div class="home-right">
          <h2 class="home-right-title">Quick Admin</h2>

          <!-- Toggles -->
          <div class="home-switch" @click="toggle('noclip')">
            <div class="home-switch-label">
              <span>No-Clip / Fly</span>
              <small>Freies Bewegen ohne Kollision.</small>
            </div>
            <div class="switch" :class="{ on: toggles.noclip }">
              <div class="knob"></div>
            </div>
          </div>

          <div class="home-switch" @click="toggle('godmode')">
            <div class="home-switch-label">
              <span>Godmode</span>
              <small>Kein Schaden für dich.</small>
            </div>
            <div class="switch" :class="{ on: toggles.godmode }">
              <div class="knob"></div>
            </div>
          </div>

          <div class="home-switch" @click="toggle('invisible')">
            <div class="home-switch-label">
              <span>Unsichtbar</span>
              <small>Network invisible + reduced Alpha.</small>
            </div>
            <div class="switch" :class="{ on: toggles.invisible }">
              <div class="knob"></div>
            </div>
          </div>

          <div class="home-switch" @click="toggle('nametags')">
            <div class="home-switch-label">
              <span>Nametags</span>
              <small>CID | Ped | Name über Spielern.</small>
            </div>
            <div class="switch" :class="{ on: toggles.nametags }">
              <div class="knob"></div>
            </div>
          </div>

          <button
            class="home-button"
            @click="portToWaypoint"
            style="margin-top:10px;width:100%;"
          >
            Port zur Kartenmarkierung
          </button>

          <div v-if="error" class="status error" style="margin-top:6px;">
            {{ error }}
          </div>

          <!-- Duty Control -->
          <div class="duty-control" style="margin-top:16px;">
            <h3 style="margin:0 0 6px;">Duty Steuerung</h3>

            <select v-model="dutySelected" class="duty-select">
              <option disabled value="">Fraktion wählen...</option>
              <option
                v-for="f in dutyFactions"
                :key="'sel-' + f.id"
                :value="String(f.id)"
              >
                {{ f.label || f.name }} ({{ f.name }})
              </option>
            </select>

            <div class="duty-buttons" style="margin-top:6px; display:flex; gap:6px;">
              <button
                class="home-button"
                :disabled="!dutySelected || dutyBusy"
                @click="setDuty(true)"
                style="flex:1;"
              >
                Einstempeln
              </button>
              <button
                class="home-button danger"
                :disabled="!dutySelected || dutyBusy"
                @click="setDuty(false)"
                style="flex:1;"
              >
                Ausstempeln
              </button>
            </div>

            <div v-if="dutyBusy" class="status" style="margin-top:4px;">
              Aktualisiere Duty...
            </div>
            <div v-if="dutyError" class="status error" style="margin-top:4px;">
              {{ dutyError }}
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
});
