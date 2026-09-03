# C — Ledger durable de reservas

Implementa `ReservationLedger` en `src/reservation-ledger.mjs` usando únicamente
Node.js estándar.

Constructor síncrono: `new ReservationLedger(filePath)`. Un path inexistente
crea lógicamente un ledger vacío. El estado se persiste como JSON y una nueva
instancia sobre el mismo path recupera el estado anterior. JSON existente
malformado lanza `Error` con `code="LEDGER_CORRUPT"`.

## `reserve({ id, owner, amount })`

- Método síncrono. Strings `id` y `owner` no vacíos; `amount` finito y positivo.
  Inputs inválidos lanzan `TypeError`.
- Crea `{ id, owner, amount, used: 0, status: "reserved" }`, lo persiste y
  devuelve una copia del registro.
- Repetir con el mismo owner/amount devuelve una copia del registro existente sin
  cambiar su estado, incluso si ya está settled o released.
- Reutilizar `id` con otro owner/amount lanza `Error` con
  `code="RESERVATION_CONFLICT"`.

## `settle(id, used)`

- Método síncrono. ID no vacío; `used` finito, no negativo y `used <= amount`;
  inputs inválidos lanzan `TypeError`.
- `reserved → settled`, persiste `used` y devuelve el registro.
- Repetir con el mismo `used` devuelve una copia del registro y es idempotente.
- ID desconocido lanza `Error` con `code="RESERVATION_NOT_FOUND"`.
- Repetir con otro `used` lanza `Error` con `code="RESERVATION_CONFLICT"`.
- Liquidar una reserva released lanza `Error` con
  `code="RESERVATION_RELEASED"`.

## `recoverOrphans(activeOwners)`

- Método síncrono. `activeOwners` debe ser un `Set` de strings no vacíos; otro
  valor lanza `TypeError`. Es el conjunto autoritativo completo de owners vivos.
- Solo cambia registros `reserved` cuyo owner NO aparece en `activeOwners`.
- Los cambia a `released`, mantiene `used=0` y persiste el resultado.
- No toca `settled` ni `released`.
- Devuelve el número de registros liberados.
- Repetir con el mismo conjunto devuelve 0 y no cambia el estado.

## `get(id)` y persistencia

- `get` requiere ID string no vacío y devuelve una copia del registro o
  `undefined`; modificar esa copia no altera el ledger.
- Tras cada mutación completada, el archivo destino contiene JSON válido y una
  nueva instancia observa el nuevo estado. La estrategia concreta de escritura y
  la inyección de crashes quedan fuera del oracle de este mini piloto.
- No mantiene locks ni promete concurrencia multiproceso.
