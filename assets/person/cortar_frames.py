#!/usr/bin/env python3
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "frames"
SCALE = 0.08
CANVAS = (112, 148)
THRESH = 22
SHEETS = [
	("CAMINATA_FRENTE.png", "frente", 3),
	("Caminata_Cavillaca_espaldas.png", "espalda", 3),
	("Caminata_Cavillaca_lateral.png", "lado", 5),
]


def cerca_blanco(pixel: tuple[int, int, int, int]) -> bool:
	return pixel[0] >= 255 - THRESH and pixel[1] >= 255 - THRESH and pixel[2] >= 255 - THRESH


def quitar_fondo(imagen: Image.Image) -> Image.Image:
	imagen = imagen.convert("RGBA")
	pixeles = imagen.load()
	ancho, alto = imagen.size
	vistos = bytearray(ancho * alto)
	cola: deque[tuple[int, int]] = deque()

	def marcar(x: int, y: int) -> None:
		if 0 <= x < ancho and 0 <= y < alto:
			cola.append((x, y))

	for x in range(ancho):
		marcar(x, 0)
		marcar(x, alto - 1)
	for y in range(alto):
		marcar(0, y)
		marcar(ancho - 1, y)

	while cola:
		x, y = cola.popleft()
		indice = y * ancho + x
		if vistos[indice]:
			continue
		vistos[indice] = 1
		color = pixeles[x, y]
		if not cerca_blanco(color):
			continue
		pixeles[x, y] = (255, 255, 255, 0)
		marcar(x + 1, y)
		marcar(x - 1, y)
		marcar(x, y + 1)
		marcar(x, y - 1)
	return imagen


def recuadro(imagen: Image.Image) -> tuple[int, int, int, int]:
	alfa = imagen.getchannel("A")
	caja = alfa.getbbox()
	if caja is None:
		return (0, 0, imagen.width, imagen.height)
	return caja


def encajar(imagen: Image.Image) -> Image.Image:
	izquierda, arriba, derecha, abajo = recuadro(imagen)
	recorte = imagen.crop((izquierda, arriba, derecha, abajo))
	ancho, alto = recorte.size
	escala = min((CANVAS[0] - 8) / ancho, (CANVAS[1] - 6) / alto)
	nuevo = recorte.resize(
		(max(1, int(ancho * escala)), max(1, int(alto * escala))),
		Image.Resampling.LANCZOS,
	)
	lienzo = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
	x = (CANVAS[0] - nuevo.width) // 2
	y = CANVAS[1] - nuevo.height - 2
	lienzo.paste(nuevo, (x, y), nuevo)
	return lienzo


def cortar(ruta: Path, prefijo: str, columnas: int) -> None:
	hoja = Image.open(ruta)
	hoja = hoja.resize(
		(max(1, int(hoja.width * SCALE)), max(1, int(hoja.height * SCALE))),
		Image.Resampling.LANCZOS,
	)
	ancho_cuadro = hoja.width // columnas
	for indice in range(columnas):
		cuadro = hoja.crop((indice * ancho_cuadro, 0, (indice + 1) * ancho_cuadro, hoja.height))
		cuadro = encajar(quitar_fondo(cuadro))
		destino = OUT / f"{prefijo}_{indice}.png"
		cuadro.save(destino, "PNG")
		print(destino.name, cuadro.size)


def main() -> None:
	OUT.mkdir(exist_ok=True)
	for archivo, prefijo, columnas in SHEETS:
		cortar(ROOT / archivo, prefijo, columnas)


if __name__ == "__main__":
	main()
