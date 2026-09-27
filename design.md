# Design — cavillaca-pov

## Tokens

- Cream panel `#FFF7ED`
- Orange header / primary `#FA9E24`
- Orange dark hover `#E67A14`
- Green accent (play / victory) `#6BC761`
- Text brown `#6B4724`
- Text on orange `#FAF9F0`
- Warm floor `#2E1F17`
- Corner radius panels `22`, headers `16`, buttons `16`, pills `20`
- White border `3–4px`, soft drop shadow

Owned by `scripts/ui_estilo.gd` (menus) and `scripts/hud.gd` (in-game).

## Menus — `scenes/MenuInicio.tscn`

- Full-bleed warm dark background; cream centered card with orange header bar
- Start: title **CAVILLACA**, subtitle Patrimonio Game Jam 2026
- Buttons: Jugar (green), Ajustes, Créditos, Salir (secondary cream)
- Settings: Master, Música, Efectos (`SFX`), Ambiente sliders on cream track with orange fill
- Credits: Melissa Huerta, Shiara, Malu, Ariadna, Selene, Miko

## HUD — `scripts/hud.gd`

- Cream status card, orange **ESTADO** header
- Energía orange fill, Presencia teal fill
- Bottom prompt pill (orange or green for attack), top combat banner
- Presence shader overlay on `Oscuridad`

## Motion

- Prompt pill fades when `Global.prompt_interaccion` changes
- Menu panels swap visibility
