-- === ui_manager.lua (client) ===
UI = {
  stack = {},          -- z.B. {"inventory","charselect"} → top = letztes
  open = {},           -- Map: name -> bool
  keepInput = false    -- ob Spiel-Input bei NUI-Focus weiterreichen darf
}

function UI.push(name, opts)
  opts = opts or {}
  if not UI.open[name] then
    UI.open[name] = true
    table.insert(UI.stack, name)
    -- NUI-Fokus setzen, wenn es eine HTML-UI ist
    if opts.nui then
      UI.keepInput = opts.keepInput or false
      SetNuiFocus(true, true)
      SetNuiFocusKeepInput(UI.keepInput)
    end
    -- optional: Event für andere Ressourcen
    TriggerEvent('LCV:ui:opened', name)
  end
end

function UI.pop(name)
  if UI.open[name] then
    UI.open[name] = false
    -- aus Stack entfernen (alle Vorkommen)
    for i = #UI.stack, 1, -1 do
      if UI.stack[i] == name then table.remove(UI.stack, i) end
    end
    -- Fokus zurückgeben, wenn keine andere NUI oben liegt
    local top = UI.current()
    if not top then
      SetNuiFocus(false, false)
      SetNuiFocusKeepInput(false)
    end
    TriggerEvent('LCV:ui:closed', name)
  end
end

function UI.isOpen(name) return UI.open[name] == true end
function UI.anyOpen() return #UI.stack > 0 end
function UI.current() return UI.stack[#UI.stack] end

LCV = LCV or {}

function LCV.OpenUI(name, opts)
  UI.push(name, opts)
end

function LCV.CloseUI(name)
  UI.pop(name)
end

-- Exports für andere Ressourcen
exports('UI_IsOpen', function(name) return UI.isOpen(name) end)
exports('UI_Current', function() return UI.current() end)
exports('UI_AnyOpen', function() return UI.anyOpen() end)
exports('LCV_OpenUI', function(name, opts, msg) LCV.OpenUI(name, opts, msg) end)
exports('LCV_CloseUI', function(name, msg) LCV.CloseUI(name, msg) end)