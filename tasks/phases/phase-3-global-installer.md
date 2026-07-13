# Fase 3: Instalador global reversible

**Files:**
- Create: `scripts/scaffolding`
- Create: `scripts/lib/paths.sh`
- Create: `scripts/lib/manifest.sh`
- Create: `tests/scaffolding_test.sh`
- Modify: `README.md`

## Step 1: Tests RED del plan de operaciones

Crear fixtures con HOME temporal para: destino ausente, archivo preexistente,
symlink correcto, symlink roto y destino gestionado por manifiesto. Verificar
que el default solo imprime un plan y no muta.

Run: `sh tests/scaffolding_test.sh`
Expected: FAIL porque `scripts/scaffolding` no existe.

## Step 2: Implementar comandos y paths

`scripts/scaffolding <install|status|doctor|uninstall> [--apply] [--home PATH]`
debe usar `set -eu`, resolver el root desde la ubicacion del script, rechazar
HOME vacio/raiz y operar solo sobre destinos allowlisted.

## Step 3: Implementar manifiesto y backup

Antes de `--apply`, crear bajo un directorio local de estado un manifest con
version, source SHA, timestamp, destino, estado anterior, checksum y backup.
Escribir temporales en el mismo filesystem y hacer rename atomico. Nunca seguir
un symlink desconocido ni sobrescribir un backup.

## Step 4: Implementar operaciones

- `install`: planifica enlaces y aplica solo tras backup.
- `status`: compara destinos, source SHA y manifest.
- `doctor`: valida enlaces, imports, permisos y dependencias, sin mutar.
- `uninstall`: restaura exactamente el estado anterior registrado.

La segunda instalacion debe ser no-op. Un conflicto produce STOP y una salida
accionable; no intenta fusion automatica de settings.

## Step 5: GREEN, calidad y commit

Run: `sh tests/scaffolding_test.sh`
Expected: PASS para dry-run, apply, idempotencia, conflicto y rollback.

Run: `sh -n scripts/scaffolding scripts/lib/*.sh tests/scaffolding_test.sh`
Expected: exit 0.

Commit: `feat: add global scaffolding installer`
