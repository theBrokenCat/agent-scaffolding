# C — Ledger durable de reservas

Implementa `ReservationLedger` en `src/reservation-ledger.mjs` usando únicamente
Node.js estándar.

Constructor: `new ReservationLedger(filePath)`. El estado se persiste como JSON
y una nueva instancia sobre el mismo path debe recuperar el estado anterior.

## `reserve({ id, owner, amount })`

- Strings `id` y `owner` no vacíos; `amount` finito y positivo.
- Crea `{ id, owner, amount, used: 0, status: "reserved" }` y lo persiste.
- Repetir exactamente la misma reserva es idempotente.
- Reutilizar `id` con otro owner/amount lanza un error de conflicto.

## `settle(id, used)`

- `used` debe ser finito, no negativo y `used <= amount`.
- `reserved → settled`, persiste `used` y devuelve el registro.
- Repetir con el mismo `used` es idempotente.
- Repetir con otro `used`, o liquidar una reserva released, lanza conflicto.

## `recoverOrphans(activeOwners)`

- `activeOwners` es el conjunto autoritativo completo de owners vivos.
- Solo cambia registros `reserved` cuyo owner NO aparece en `activeOwners`.
- Los cambia a `released`, mantiene `used=0` y persiste el resultado.
- No toca `settled` ni `released`.
- Devuelve el número de registros liberados.
- Repetir con el mismo conjunto devuelve 0 y no cambia el estado.

## `get(id)` y persistencia

- `get` devuelve una copia del registro o `undefined`.
- Cada mutación escribe un fichero temporal en el mismo directorio y termina con
  `rename`, para que el archivo destino nunca quede parcialmente escrito.
- No mantiene locks ni promete concurrencia multiproceso; esa capacidad queda
  explícitamente fuera de scope.

