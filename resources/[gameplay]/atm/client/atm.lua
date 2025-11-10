-- lcv-atm/client/atm.lua
-- ATM UI showing account number + balance; deposit/withdraw via ox_lib

local currentAccount = { number = '--------', balance = 0 }

local function refreshAccount()
  local res = lib.callback.await('LCV:atm:server:getAccount', false)
  if not res or not res.ok then
    lib.notify({ description = res and res.err or 'Konto nicht verfügbar', type = 'error' })
    return false
  end
  currentAccount.number = res.account_number
  currentAccount.balance = tonumber(res.balance) or 0
  return true
end

local function openATM()
  if not refreshAccount() then return end
  lib.registerContext({
    id = 'lcv_atm_menu',
    title = ('Konto %s | Kontostand: $%s'):format(currentAccount.number, math.floor(currentAccount.balance)),
    options = {
      { title = 'Einzahlen',    description = 'Geld vom Inventar aufs Konto', icon = 'plus-circle',   event = 'LCV:atm:client:deposit' },
      { title = 'Abheben',      description = 'Geld vom Konto ins Inventar',  icon = 'minus-circle',  event = 'LCV:atm:client:withdraw' },
      --{ title = 'Überweisen',  description = 'An anderen Spieler senden',    icon = 'share-nodes',   event = 'LCV:atm:client:transfer' },
    }
  })
  lib.showContext('lcv_atm_menu')
end

RegisterNetEvent('LCV:atm:client:open', function(entity)
  local ped = PlayerPedId()
  if entity and entity ~= 0 and #(GetEntityCoords(ped) - GetEntityCoords(entity)) > 2.0 then return end
  openATM()
end)

local function numberDialog(title)
  local input = lib.inputDialog(title, {
    { type = 'number', label = 'Betrag', placeholder = 'z. B. 250', required = true, min = 1, step = 1 }
  })
  if input and input[1] and tonumber(input[1]) then
    return math.floor(tonumber(input[1]))
  end
  return nil
end

AddEventHandler('LCV:atm:client:deposit', function()
  local amt = numberDialog('Einzahlen')
  if not amt then return end
  local ok, newBal, msg = lib.callback.await('LCV:atm:server:deposit', false, amt)
  lib.notify({ description = msg or (ok and 'Einzahlung erfolgreich' or 'Fehlgeschlagen'), type = ok and 'success' or 'error' })
  if ok then
    currentAccount.balance = newBal
    lib.setContextTitle('lcv_atm_menu', ('Konto %s | Kontostand: $%s'):format(currentAccount.number, math.floor(newBal)))
  end
end)

AddEventHandler('LCV:atm:client:withdraw', function()
  local amt = numberDialog('Abheben')
  if not amt then return end
  local ok, newBal, msg = lib.callback.await('LCV:atm:server:withdraw', false, amt)
  lib.notify({ description = msg or (ok and 'Abhebung erfolgreich' or 'Fehlgeschlagen'), type = ok and 'success' or 'error' })
  if ok then
    currentAccount.balance = newBal
    lib.setContextTitle('lcv_atm_menu', ('Konto %s | Kontostand: $%s'):format(currentAccount.number, math.floor(newBal)))
  end
end)