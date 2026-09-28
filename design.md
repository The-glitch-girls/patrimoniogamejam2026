# Design — cavillaca-pov

All of You language: round fills, white outline, Fredoka, cream type.

## Tokens

- Cream `#FDF5E6`
- Purple card `#38336B`
- Jugar / energia `#7DC24A`
- Ajustes / dorado `#DBB233`
- Creditos / presencia `#AB9EED`
- Salir / ataque `#9E3D5C`
- Outline white `5–6px`
- Radius circles `88`, cards `22`, bars `10`
- Shadow `(0, 4)`
- Type: Fredoka SemiBold

## Start — `scenes/MenuInicio.tscn`

- Night map + purple wash
- Title Cavillaca 72
- Circles: Jugar, Ajustes, Creditos, Salir
- Captions under the circles

## Entities

### Cavillaca — `scenes/Cavillaca.tscn`

- Sprite sheets in `assets/person/`, frames 112x148 in `assets/person/frames/`
- Front 3, back 3, side 5 (flip for left)
- Idle uses the standing frame; walk plays the sheet
- Purple dress, braid, white hem. No ColorRect body.

## HUD — `scripts/hud.gd`

- No card, no title
- Energia: 36px green circle, white bolt `assets/icons/energia.svg`, green pill with 4px white outline
- Presencia (Cuniraya): 36px lilac circle, white eye, lilac pill; only when value > 0
- Prompt: 56px green circle, letter E, bottom-right; burgundy if attack
- Settings: 52px gold circle, white gear `assets/icons/ajustes.svg`, top-right; opens Sonido card
- Combat banner same pill, only when it fires
