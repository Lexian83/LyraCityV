# CLV Character Select (Server + Client)

## Ensure order
```
ensure oxmysql
ensure ox_lib
ensure log           # optional, wenn du CLV.Util.log nutzt
ensure clv_charselect
```

## ACE für Erstellung (optional)
```
add_ace builtin.everyone clv.char.create allow
# oder feiner:
# add_principal identifier.license:xxxxxxxx clv.char.create
```

## Test
- Ingame: `/charselect`
- Serverkonsole: `clv_open <playerId>`

## Spawn Hook
Höre serverseitig auf `clv:charselect:spawn` (src, charId) und lade dort deinen Character (Position, Inventar, etc.).