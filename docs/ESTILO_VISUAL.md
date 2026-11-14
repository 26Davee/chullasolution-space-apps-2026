# Estilo visual · low-poly con luz suave

Dueños: puesto 3 (modelos y luz) y puesto 6 (interfaz). Se parece a una maqueta o diorama. Esta es la opción A de la decisión 7, elegida por el líder.

## Cómo se ve

- **Formas simples y gordas.** Pocas caras, aristas biseladas, patas y ventanas grandes, todo redondeado y amigable.
- **Caras planas.** Se nota cada faceta; sin superficies lisas ni texturas realistas.
- **Pocos colores y un acento.** Casco blanco hueso, detalles turquesa, terreno gris violáceo y cielo azul marino casi negro.
- **Luz cálida con brillo propio.** Ventanas y lámparas en naranja, y un resplandor turquesa bajo la cápsula.
- **Escena de diorama.** La base es un disco de terreno flotando en el espacio, con el Sol y la Tierra pequeños al fondo.

## Paleta

| Uso | Color |
|---|---|
| Cielo | `#0B1F3A` y `#06132A` |
| Terreno de la Luna | `#A09BAB` y `#6F7A8F` |
| Casco blanco hueso | `#DBCFC7` |
| Acento turquesa | `#2BA3B0` |
| Luz de ventanas y lámparas | `#C88230` |

## Cómo se logra en Godot

- Modelar con cubos, cilindros de 6 a 10 lados y prismas. Exportar de Blender con sombreado plano (*Shade Flat*). Las esferas y cilindros automáticos de Godot salen lisos: sirven solo como piezas provisionales.
- Materiales `StandardMaterial3D` de un solo color, con *roughness* alto y sin metal. La emisión solo en ventanas, lámparas y la luz bajo la cápsula.
- Un `DirectionalLight3D` cálido con sombras suaves y luz ambiental azulada en el `WorldEnvironment`.
- El polvo con `CPUParticles3D`, que es lo más seguro para la versión web.
- El proyecto usa el renderizador Compatibility, que no tiene varios efectos avanzados. Lo que se puede reproducir es el color, la forma y la luz.

## Reglas

- Las imágenes de referencia hechas con IA solo sirven para alinear al equipo. Si una entra al demo, al póster o a la página del proyecto, lleva marca de agua visible y se anota en `docs/AI_USE.md`.
- El arte final lo hacemos nosotros. No se copia arte de otros juegos.
