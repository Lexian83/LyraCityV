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