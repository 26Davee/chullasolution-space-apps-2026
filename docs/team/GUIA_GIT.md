# Subir y bajar cambios, explicado simple

## La idea en una imagen

Piensa en un **cuaderno compartido guardado en internet** (GitHub) y en **seis fotocopias** del cuaderno, una en cada computadora.

- Tú trabajas en **tu fotocopia**. Nadie ve lo que haces hasta que decides subirlo.
- Cuando algo funciona, lo **subes** al cuaderno de internet.
- Para ver lo que subieron los demás, **bajas** lo nuevo a tu fotocopia.
- Nada se actualiza solo: subir y bajar son botones que tú pulsas. Por eso lo hacemos al empezar cada bloque de trabajo.

## Las palabras, en una línea cada una

| Palabra | Qué es |
|---|---|
| **Repositorio** | El cuaderno compartido, con todas las carpetas y su historia. |
| **Clonar** | Hacer tu fotocopia completa. Se hace **una sola vez**. |
| **Fetch origin** | Mirar si hay novedades en internet, sin cambiar tu copia. |
| **Pull origin** | Traer esas novedades a tu copia. |
| **Rama (branch)** | Una hoja aparte donde trabajas sin tocar la principal. |
| **Commit** | Guardar una versión con una nota («agregué el panel de energía»). Pasa en tu computadora. |
| **Push origin** | Subir tus commits a internet. |
| **Pull Request** | Pedir que tu rama se pegue en la principal (`main`). Alguien la revisa antes. |
| **Merge** | El pegado. Lo hace el puesto 1. |
| **`main`** | La versión buena del juego. Siempre debe abrir con F5. |

## Una sola vez: bajar el proyecto

1. Instala **GitHub Desktop** e inicia sesión con tu cuenta de GitHub.
2. Acepta la invitación al repositorio (llega a tu correo o la ves en GitHub).
3. En GitHub Desktop: `File ▸ Clone repository… ▸ GitHub.com`, elige el repositorio del equipo.
4. En `Local path` pon `C:\ChullaSolution\` (no dentro de OneDrive ni de Escritorio). Pulsa `Clone`.
5. Abre Godot ▸ `Import` (en español, `Importar`) ▸ elige `project.godot` dentro de esa misma carpeta ▸ `Import & Edit`.
   **Usa siempre `Import`, nunca `Create`:** el proyecto ya existe y crear uno nuevo lo deja en otra carpeta.
6. Pulsa `F5`. Si ves una Luna gris y el texto «proyecto base OK», ya estás dentro.

## Cada bloque de trabajo

**Al empezar (bajar lo de los demás):**
1. En GitHub Desktop, rama `main`, pulsa `Fetch origin`. Si cambia a `Pull origin`, púlsalo.
2. `Branch ▸ New branch…` y ponle nombre: `p<tu número>/<tarea>` (ejemplo: `p4/camara`).

**Mientras trabajas:**
3. En Godot guarda con `Ctrl+Shift+S` seguido. Godot no guarda solo.

**Cuando algo funcione (subir lo tuyo):**
4. En GitHub Desktop verás tus archivos cambiados en la pestaña `Changes`.
5. Escribe una frase corta abajo a la izquierda y pulsa `Commit to p4/camara`.
6. Pulsa `Push origin` (la primera vez dice `Publish branch`).
7. Pulsa `Create Pull Request`. Se abre GitHub en el navegador: llena la plantilla corta y pulsa `Create pull request`.
8. Avisa en el grupo: «PR listo de [tu parte]».

**Después de que el puesto 1 fusione:**
9. Vuelve a la rama `main` y pulsa `Fetch origin` y `Pull origin`. Ahora tu copia tiene el trabajo de todos.

## Si cambian `main` mientras trabajas en tu rama

`Branch ▸ Update from main`. Trae lo nuevo a tu rama. Si aparece un conflicto, **para y avisa en el grupo**; no resuelvas a ciegas.

## Godot y GitHub Desktop deben mirar la misma carpeta

La carpeta que abres en Godot es la misma que ve GitHub Desktop. Si cambias una rama o haces `Pull`, Godot puede avisar que los archivos cambiaron: pulsa `Reload` o `Reload from disk`.

## Lo que no se hace

- `Discard changes` y `Reset`: borran tu trabajo sin vuelta atrás.
- Subir directo a `main`.
- Tocar archivos de otro puesto sin avisar.
- Copiar el proyecto a un USB, a Drive o a otra carpeta «para juntarlo después».

## Si algo sale raro

| Qué pasa | Qué haces |
|---|---|
| GitHub Desktop no muestra mis cambios | Falta guardar en Godot (`Ctrl+Shift+S`). |
| No veo el repositorio al clonar | Falta aceptar la invitación; revisa tu correo. |
| `Push` pide usuario o contraseña | Cierra sesión y vuelve a entrar en `File ▸ Options ▸ Accounts`. |
| Mensaje de conflicto | Para. Escribe el nombre del archivo en el grupo. |
| Godot no abre el proyecto | Revisa que importaste `project.godot` de la carpeta clonada (con `Import`, no `Create`). En el panel de archivos de Godot deben verse `core`, `docs`, `world`, `ui`… Si solo ves `icon.svg`, abriste otra carpeta. |
| Hice un commit en `main` por error | No hagas `Reset`. Avisa en el grupo; se arregla en dos minutos. |
