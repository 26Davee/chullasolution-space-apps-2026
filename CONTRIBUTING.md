# Cómo colaborar

## La regla de oro

**Un repositorio, un proyecto de Godot, seis copias locales, una carpeta = un dueño.**

Tú solo cambias lo que está en **tus** carpetas (mira [`docs/QUIEN_TOCA_QUE.md`](docs/QUIEN_TOCA_QUE.md)). Si necesitas algo de otra persona, se lo pides en el grupo. Así nadie pisa el trabajo de nadie.

## El ciclo de cada bloque de trabajo (GitHub Desktop)

1. **Bajar lo último.** Elige `main` y pulsa `Fetch origin`; si el botón cambia a `Pull origin`, púlsalo.
2. **Crear tu rama.** `Branch ▸ New branch`. Nombre: `p<tu número>/<tarea>`, por ejemplo `p3/terreno`, `p6/panel-barras`, `p2/modelo-energia`.
3. **Trabajar y guardar.** En Godot, `Ctrl+Shift+S` (Godot no guarda solo).
4. **Commit.** Vuelve a GitHub Desktop, escribe una frase corta de lo que hiciste y pulsa `Commit`.
5. **Subir.** `Push origin` (la primera vez dirá `Publish branch`).
6. **Pull Request.** Botón `Create Pull Request`, llena la plantilla corta.
7. **Revisión.** Tu pareja de revisión mira que el juego abra con F5 y aprueba; después el puesto 1 fusiona.
8. **Todos bajan.** Cuando se fusiona, todos vuelven a `main` y hacen `Pull origin`.

Parejas de revisión: **2 ↔ 5 · 3 ↔ 4 · 6 ↔ 1**.

Haz cambios pequeños y frecuentes: es mejor un Pull Request al día de poco que uno enorme al final.

## Reglas que evitan problemas

- **Nadie sube directo a `main`.** Todo entra por Pull Request.
- **Solo el puesto 1 toca `scenes/main.tscn` y `project.godot`.** Cada puesto crea su propia escena dentro de su carpeta (por ejemplo `ui/hud.tscn`) y el puesto 1 la conecta. Los archivos `.tscn` y `.tres` se mezclan muy mal, por eso cada uno tiene dueño.
- **No uses `Discard changes` ni `Reset`** si no estás seguro: borran trabajo sin vuelta atrás. Si algo se complica, avisa en el grupo.
- **Si el juego no abre con F5, no pidas fusión.**
- **Nunca subas** contraseñas, llaves, tokens, datos personales ni fotos de menores. Tampoco `.godot/` ni `builds/` (ya están ignorados).
- **Archivos pesados:** si pasa de 20 MB, avisa antes de subirlo.
- **Misma carpeta:** la carpeta que abres en Godot debe ser la misma que ve GitHub Desktop. No copies el proyecto a otro lado.

## Consejos de Godot que evitan sustos

- **Todos usamos Godot 4.7.2.** Si Godot ofrece «actualizar el proyecto» o «convertir», no aceptes y avisa en el grupo.
- **Mueve y renombra archivos solo desde el panel `FileSystem` de Godot**, no desde el Explorador de Windows. Así Godot actualiza las referencias y nada se rompe.
- **Nombres sin espacios ni tildes y en minúsculas con guion bajo:** `panel_energia.gd`, `moon_world.tscn`.
- **Si falta un modelo o un dibujo, usa un cubo de color.** Tu parte funciona igual y después se cambia.
- **Si Godot avisa que los archivos cambiaron en disco** (después de un `Pull`), pulsa `Reload`.
- **Guarda siempre antes de ir a GitHub Desktop:** `Ctrl+Shift+S`.

## Registros obligatorios (cada quien en su archivo)

Cada persona lleva `docs/registro/puesto-N.md`. Se anota al momento, no al final:

- **Uso de IA:** qué parte hiciste con ayuda de IA y con qué herramienta.
- **Material de terceros:** imagen, sonido, fuente o modelo que no es nuestro, con autor y licencia.
- **Datos de NASA:** enlace oficial, fecha, unidades y qué le hiciste.

El puesto 1 junta los seis registros en `docs/AI_USE.md`, `docs/ASSETS_LICENSES.md` y `docs/DATA_PROVENANCE.md` antes del envío.

## Si hay un conflicto

GitHub Desktop avisa con un mensaje de conflicto. **No sobrescribas a ciegas.** Escribe en el grupo el nombre del archivo, mira los dos cambios con la otra persona y resuelvan en tu rama. Prueba con F5 antes de fusionar.

## Si subiste algo que no debías

Una llave o contraseña subida por error: **no la borres tú solo**, avisa de inmediato. Hay que cambiar la llave y limpiar el historial.
