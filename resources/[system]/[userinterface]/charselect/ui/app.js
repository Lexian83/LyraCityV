let state = {
  canCreate: false,
  maxCharacters: 2,
  characters: [],
  isNewAccount: false, // 👈 neu
};

function statusClass(s) {
  if (s === "coma") return "status coma";
  if (s === "wildlife") return "status wildlife";
  return "status";
}
function statusText(s) {
  if (s === "coma") return "KOMA";
  if (s === "wildlife") return "WILDLIFE";
  return "NORMAL";
}

// -------- Gender Badge --------
function normGender(val) {
  // erst numerisch versuchen
  const n = Number(val);
  if (!Number.isNaN(n)) {
    if (n === 1) return "male";
    if (n === 0) return "female";
  }
  // sonst stringbasiert
  const v = String(val ?? "")
    .trim()
    .toLowerCase();
  if (v === "1" || v === "m" || v === "male" || v === "mann") return "male";
  if (
    v === "0" ||
    v === "f" ||
    v === "female" ||
    v === "frau" ||
    v === "weiblich"
  )
    return "female";
  return "other";
}

function render() {
  const app = document.getElementById("app");
  app.classList.remove("hidden");
  const grid = document.getElementById("grid");
  grid.innerHTML = "";

  const wrap = document.createElement("div");
  wrap.className = "tiles";

  // Nur nicht-gesperrte Chars
  const items = state.characters.filter((c) => !c.is_locked);

  items.forEach((c) => {
    const tile = document.createElement("button");
    tile.className = "tile";
    tile.setAttribute("aria-label", `Char ${c.name} ${c.tname}`);
    tile.onclick = () =>
      fetch(`https://${GetParentResourceName()}/selectCharacter`, {
        method: "POST",
        body: JSON.stringify({ id: c.id }),
      });

    const g = normGender(c.gender);
    tile.dataset.gender = g;

    const gender = document.createElement("span");
    gender.className = "gender-badge";
    gender.title =
      g === "male" ? "Männlich" : g === "female" ? "Weiblich" : "Divers";
    gender.textContent = g === "male" ? "♂" : g === "female" ? "♀" : "⚧";
    tile.appendChild(gender);

    const portrait = document.createElement("div");
    portrait.className = "portrait";
    if (c.portrait) {
      portrait.style.backgroundImage = `url(${c.portrait})`;
    } else {
      portrait.style.backgroundImage = `url(assets/portrait_silhouette.svg)`;
    }

    const name = document.createElement("div");
    name.className = "name";
    name.textContent = `${c.name}`;

    const dob = document.createElement("div");
    dob.className = "dob";
    // Server liefert "birthdate" (YYYY-MM-DD) und "birthday" (DD.MM.YYYY)
    dob.textContent = c.birthdate || c.birthday || "ICH FEHLE";

    const status = document.createElement("div");
    status.className = statusClass(c.status);
    status.innerHTML = `<span class="label">Status:</span><span class="value">${statusText(
      c.status
    )}</span>`;

    tile.appendChild(portrait);
    tile.appendChild(name);
    tile.appendChild(dob);
    tile.appendChild(status);
    wrap.appendChild(tile);
  });

  // 👉 Plus-Kachel NUR, wenn:
  // - Server sagt canCreate == true
  // - Account ist wirklich "neu" (accounts.new == 1)
  // - und wir unterhalb des maxCharacters-Limits sind
  if (
    state.canCreate &&
    state.isNewAccount &&
    items.length < state.maxCharacters
  ) {
    const tile = document.createElement("button");
    tile.className = "tile";
    tile.onclick = () =>
      fetch(`https://${GetParentResourceName()}/createCharacter`, {
        method: "POST",
        body: "{}",
      });
    const plus = document.createElement("div");
    plus.className = "plus";
    plus.textContent = "+";
    tile.appendChild(plus);
    wrap.appendChild(tile);
  }

  grid.appendChild(wrap);
}

// NUI message handling
window.addEventListener("message", (e) => {
  const { action, payload } = e.data || {};
  if (action === "setData" && payload) {
    // payload enthält jetzt zusätzlich isNewAccount
    state = Object.assign({}, state, payload);
  }
  if (action === "open") {
    document.getElementById("app").classList.remove("hidden");
  }
  if (action === "close") {
    document.getElementById("app").classList.add("hidden");
  }
  if (action === "open" || action === "setData") {
    render();
  }
});
