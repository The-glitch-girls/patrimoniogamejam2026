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

### Halcón — `scenes/Halcon.tscn`

- Frames 1024×600, sprite scale `0.24`
- Orbits Cavillaca at about 36–108px. Passing within 52px costs energy, then it cannot strike again for 1.1s. It does not dive in to strike. The hit pose stays up during that lock
- If she gets 260px away, it peels off and appears at a random open tile 600–1400px further ahead
- Same flutter at each later point. Stones still hit it while it is circling

### Cavillaca — `scenes/Cavillaca.tscn`

- Sprite sheets in `assets/person/`, frames 112x148 in `assets/person/frames/`
- Front 3, back 3, side 5 (flip for left)
- Idle uses the standing frame; walk plays the sheet
- Walk 200 px/s, sprite `speed_scale` 1.7. Shift run 300 px/s, sprite `speed_scale` 2.0
- Purple dress, braid, white hem. No ColorRect body.

## HUD — `scripts/hud.gd`

- No card, no title
- Energia: 36px green circle, white bolt `assets/icons/energia.svg`, green pill with 4px white outline
- Presencia (Cuniraya): 36px lilac circle, white eye, lilac pill; only when value > 0
- Prompt: 56px green circle, letter E, bottom-right; burgundy if attack
- Settings: 52px gold circle, white gear `assets/icons/ajustes.svg`, top-right; opens Sonido card
- Combat banner same pill, only when it fires
- Baby guide: green pill, radius 22, 4px white outline, cream distance in Fredoka 18. The white arrow sits on the side it points. Sits on the screen edge toward the baby when it is off-camera and Cavillaca is not carrying it. 2.2 px = 1 m, rounded to 10 m
- Recuerdos: three 22px circles to the right of the energy bar. Empty purple `#38336B`, filled gold `#DBB233`, 3px white outline

## Flashbacks — `scenes/Flashback.tscn`

- Purple wash `#1F1A47` at 72%
- Title 36 Fredoka cream, body 22
- Continuar: green pill, 22 radius, 5px white outline

## Finales — `scenes/Final.tscn`

- Same night photo + purple wash as the start menu
- Title 64 cream with 10px outline
- One line under the title in lilac
- Green play circle + caption "Volver a jugar"
