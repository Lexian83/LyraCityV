-- atm/server/atm_statement.lua
-- Statement fetcher from bank_log

local function getCharId(src)
  if exports['playerManager'] and exports['playerManager'].GetPlayerData then
    local pdata = exports['playerManager']:GetPlayerData(src)
    if pdata and pdata.character and pdata.character.id then
      return tonumber(pdata.character.id)
    end
  end
  return nil
end

local function getAccountByOwner(owner)
  return MySQL.single.await('SELECT account_number FROM bank_accounts WHERE owner = ? LIMIT 1', { owner })
end

lib.callback.register('LCV:atm:server:getStatement', function(source, limit, offset)
  limit = tonumber(limit) or 25
  offset = tonumber(offset) or 0
  local charId = getCharId(source)
  if not charId then return {} end

  local acc = getAccountByOwner(charId)
  if not acc or not acc.account_number then return {} end

  local rows = MySQL.query.await(([[
    SELECT id, account_number, kind, amount, source, destination, meta, created_at
    FROM bank_log
    WHERE account_number = ?
    ORDER BY id DESC
    LIMIT ? OFFSET ?
  ]]), { acc.account_number, limit, offset })

  return rows or {}
end)