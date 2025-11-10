-- lcv-atm/server/atm.lua
-- Banking with dedicated tables: bank_accounts & bank_log
-- Cash (keine ox_inventory): wallets-Tabelle (owner=charId, cash=int)

local function getCharId(src)
  if exports['playerManager'] and exports['playerManager'].GetPlayerData then
    local pdata = exports['playerManager']:GetPlayerData(src)
    if pdata and pdata.character and pdata.character.id then
      return tonumber(pdata.character.id)
    end
  end
  return nil
end

-- === helpers: bank account ===
local function generateUniqueAccountNumber()
  while true do
    local num = tostring(math.random(10000000, 99999999))
    local row = MySQL.single.await('SELECT id FROM bank_accounts WHERE account_number = ?', { num })
    if not row then return num end
  end
end

local function getOrCreateAccount(charId)
  local row = MySQL.single.await('SELECT id, owner, account_number, balance FROM bank_accounts WHERE owner = ? LIMIT 1', { charId })
  if row then return row end
  local num = generateUniqueAccountNumber()
  local id = MySQL.insert.await('INSERT INTO bank_accounts (owner, account_number, balance) VALUES (?, ?, 0)', { charId, num })
  return { id = id, owner = charId, account_number = num, balance = 0 }
end

local function logMovement(account_number, kind, amount, source, destination, meta)
  MySQL.insert.await(([[
    INSERT INTO bank_log (account_number, kind, amount, source, destination, meta)
    VALUES (?, ?, ?, ?, ?, ?)
  ]]), { account_number, kind, amount, source, destination, meta and json.encode(meta) or nil })
end

-- === helpers: wallet (bare cash, no inventory framework) ===
local function getOrCreateWallet(charId)
  local w = MySQL.single.await('SELECT owner, cash FROM wallets WHERE owner = ? LIMIT 1', { charId })
  if w then return w end
  MySQL.insert.await('INSERT INTO wallets (owner, cash) VALUES (?, 0)', { charId })
  return { owner = charId, cash = 0 }
end

-- atomar: dec wallet if enough
local function walletTryTake(charId, amount)
  local affected = MySQL.update.await('UPDATE wallets SET cash = cash - ? WHERE owner = ? AND cash >= ?', { amount, charId, amount })
  return affected and affected > 0
end

local function walletAdd(charId, amount)
  MySQL.update.await('UPDATE wallets SET cash = cash + ? WHERE owner = ?', { amount, charId })
end

-- === callbacks ===

lib.callback.register('LCV:atm:server:getAccount', function(source)
  local charId = getCharId(source)
  if not charId then
    return { ok = false, err = 'Kein aktiver Character.' }
  end
  local acc = getOrCreateAccount(charId)
  return { ok = true, account_number = acc.account_number, balance = acc.balance }
end)

lib.callback.register('LCV:atm:server:deposit', function(source, amount)
  amount = tonumber(amount) or 0
  if amount <= 0 then return false, nil, 'Ungültiger Betrag' end

  local charId = getCharId(source)
  if not charId then return false, nil, 'Kein aktiver Character.' end
  local acc = getOrCreateAccount(charId)
  getOrCreateWallet(charId)

  -- 1) cash vom wallet abziehen (nur wenn genug)
  if not walletTryTake(charId, amount) then
    local w = MySQL.single.await('SELECT cash FROM wallets WHERE owner = ?', { charId })
    local cash = (w and w.cash) or 0
    return false, acc.balance, ('Nicht genug Bargeld (%d < %d)'):format(cash, amount)
  end

  -- 2) konto erhöhen
  MySQL.update.await('UPDATE bank_accounts SET balance = balance + ? WHERE account_number = ?', { amount, acc.account_number })
  local newBal = MySQL.scalar.await('SELECT balance FROM bank_accounts WHERE account_number = ?', { acc.account_number }) or (acc.balance + amount)

  logMovement(acc.account_number, 'deposit', amount, 'wallet', 'account', { by = source, owner = charId })
  return true, newBal, ('Neuer Kontostand: $%d'):format(newBal)
end)

lib.callback.register('LCV:atm:server:withdraw', function(source, amount)
  amount = tonumber(amount) or 0
  if amount <= 0 then return false, nil, 'Ungültiger Betrag' end

  local charId = getCharId(source)
  if not charId then return false, nil, 'Kein aktiver Character.' end
  local acc = getOrCreateAccount(charId)
  getOrCreateWallet(charId)

  -- 1) konto verringern, nur wenn genug drauf
  local affected = MySQL.update.await('UPDATE bank_accounts SET balance = balance - ? WHERE account_number = ? AND balance >= ?', { amount, acc.account_number, amount })
  if not affected or affected < 1 then
    return false, acc.balance, 'Kontostand zu niedrig'
  end

  -- 2) wallet erhöhen
  walletAdd(charId, amount)
  local newBal = MySQL.scalar.await('SELECT balance FROM bank_accounts WHERE account_number = ?', { acc.account_number }) or 0

  logMovement(acc.account_number, 'withdraw', amount, 'account', 'wallet', { by = source, owner = charId })
  return true, newBal, ('Neuer Kontostand: $%d'):format(newBal)
end)