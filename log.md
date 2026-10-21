# Bitácora del fork personal de Boring Notch

Aquí registramos qué cambiamos, por qué y cómo mantenerlo. Agrega una entrada nueva arriba de **Historial** cada vez que hagamos algo.

## Estado actual

| | |
|---|---|
| Base de ellos | tag `v2.8-rc.2` (beta), guardada en el tag `fork-base` |
| Rama nuestra | `personal` (nunca se sube a GitHub) |
| Remoto de ellos | `upstream` → `TheBoredTeam/boring.notch` (su rama activa es `dev`, no `main`) |
| App instalada | `/Applications/Boring Notch.app`, la única copia del sistema |
| Actualizaciones automáticas | apagadas (Sparkle desactivado) |

### Qué tiene nuestra versión que no tiene la oficial
- **Pestañas tipo píldora**: la pestaña activa muestra su nombre, y toda la píldora se puede cliquear.
- **Pomodoro**: tiempos configurables, anillo en el notch cerrado, sonido y aviso al terminar cada sesión.
- **Stats**: CPU, memoria, temperatura del chip, disco libre y la app que más consume.
- **PR #1711** (de un colaborador, todavía no aprobado arriba): cambiar entre pestañas del navegador que reproducen YouTube u otros medios.

## Cómo actualizar (más o menos cada mes)

```sh
cd ~/Developer/boring.notch
scripts/update-from-upstream.sh          # última versión publicada (tag v2.*)
scripts/update-from-upstream.sh dev      # o la rama de desarrollo de ellos
```

El script trae lo nuevo, crea un tag de respaldo `backup/<fecha>`, re-aplica nuestros commits encima (`git rebase` con `rerere`) y reinstala la app.

**Si se detiene por un conflicto:** resuelve los archivos que indique, luego `git add` y `git rebase --continue`, y al final haz lo que el script imprime. Para volver atrás: `git rebase --abort && git reset --hard backup/<fecha>`.

**Si ellos ya aprobaron el PR #1711:** git descarta solos nuestros 2 commits del PR. Si chocan, se eliminan con `git rebase --skip`.

**Después de actualizar, revisa:**
- que existan las 4 pestañas;
- el Pomodoro abierto y cerrado;
- que Stats muestre la temperatura;
- YouTube en Brave;
- que `mdfind "kMDItemCFBundleIdentifier == 'theboringteam.boringnotch'"` devuelva una sola app.

Solo reinstalar, sin actualizar: `scripts/install-local.sh`.

## Dónde vive nuestro código

**Archivos propios** (ellos nunca los tocan, así que no generan conflictos):
- `boringNotch/Fork/`: carpeta sincronizada; Xcode incluye sola cualquier archivo nuevo.
  - `ForkDefaults.swift`: preferencias (`pomodoro*`, `statsEnabled`).
  - `ForkTabs.swift`: pestañas extra y cuándo mostrar la barra.
  - `Pomodoro/`: `PomodoroManager`, `PomodoroView`, `PomodoroLiveActivity`, `ContentView+Pomodoro`.
  - `Stats/`: `SystemStatsManager`, `StatsView`.
- `boringNotch/components/Settings/Views/PomodoroSettingsView.swift` y `StatsSettingsView.swift`.
- `BoringNotchXPCHelper/SystemSensors.swift` y `BoringNotchXPCHelper+Stats.swift`: temperatura y CPU por app. Corren en el helper, que no tiene sandbox.
- `scripts/install-local.sh` y `scripts/update-from-upstream.sh`.

**Ganchos en archivos de ellos** (búscalos con `git grep -n "// fork"`):
- `enums/generic.swift`: `case pomodoro`, `case stats`.
- `BoringViewCoordinator.swift`: `case pomodoro` en `SneakContentType`.
- `ContentView.swift`: observar el Pomodoro, la actividad del notch cerrado, el ancho, la máscara del tap y las vistas de las pestañas.
- `components/Tabs/TabSelectionView.swift` y `TabButton.swift`: estilo píldora y `ForkTabs.extra`.
- `components/Notch/BoringHeader.swift`: mostrar la barra de pestañas.
- `components/Settings/SettingsView.swift`: secciones Pomodoro y Stats.
- `Shared/BoringNotchXPCHelperProtocol.swift` y `XPCHelperClient/XPCHelperClient.swift`: llamadas de Stats al helper.
- `boringNotchApp.swift` (`startUpdater()` comentado) e `Info.plist` (sin `SUFeedURL`).

**Regla:** las funciones nuevas van en archivos propios. En los archivos de ellos solo agregamos ganchos de 1 a 3 líneas, marcados con `// fork`.

## Cosas que aprendimos (no repetir)
- **Sparkle reemplazó nuestra app por la oficial.** Nuestra build decía ser una versión más vieja, así que Sparkle "actualizó" encima. Por eso está desactivado.
- **Las builds Release fallaban al abrir** (`Library not loaded … different Team IDs`). Con firma local (ad-hoc), el hardened runtime rechaza los frameworks. El script compila con `ENABLE_HARDENED_RUNTIME=NO`.
- **En la 2.7.3 los archivos nuevos no entraban solos al proyecto** y había que registrarlos en `project.pbxproj`. Ahora usamos la carpeta sincronizada `Fork/`.
- **Caché de compilación vieja:** después de cambiar de versión base, si sale el error `has been modified since the module file … was built`, borra la carpeta `build/`.
- **Al reinstalar quedaban procesos huérfanos** (`mediaremote-adapter.pl`) de la app anterior. El script ya los cierra.

## Historial

### 2026-10-21: Migración a la 2.8-rc.2 + PR #1711
- Rama `personal` creada desde `v2.8-rc.2`. Commits:
  - `77d61cc`, `c3eda70`: PR #1711, pestañas de medios del navegador (autor original conservado).
  - `77052b6`: Sparkle apagado y scripts de instalación y actualización.
  - `3b460aa`: pestañas tipo píldora y carpeta `Fork/`.
  - `5578926`: Pomodoro.
  - `83cd4d6`: Stats.
  - `bb51e54`: el script cierra los procesos huérfanos.
- La app pasó a llamarse `Boring Notch.app` (cambio de ellos en la 2.8). Tus ajustes se conservaron.
- Ensayo de actualización contra `upstream/dev`: nuestros commits se aplicaron sin conflictos.
- Respaldo de la versión anterior: rama `pomodoro`, tag `backup/2.7.3-fork` y `~/Developer/boring.notch-backups/boringNotch-2.7.3-fork.zip`.

### 2026-10-21: Fork sobre la 2.7.3 (rama `pomodoro`, ya reemplazada)
- Pestaña Pomodoro; pestañas tipo píldora; pestaña Stats.
- Se desinstaló la versión de Homebrew (`brew uninstall --cask boring-notch`) para tener una sola app.

## Ideas pendientes
- Estadísticas del Pomodoro (focos por día y racha).
- Activar un modo Concentración de macOS al iniciar un foco.
- Cuenta regresiva hasta la próxima reunión del calendario.
- PRs de ellos que podrían interesar: #1715 (pegar en la Bandeja), #1717/#1721 (notificaciones en el notch), #1672/#1698 (Liquid Glass).
