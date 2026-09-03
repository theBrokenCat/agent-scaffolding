# A — Normalización mecánica de header

Implementa `normalizeHeaderName(value)` en `src/header-name.mjs`.

Contrato:

- `value` debe ser string; otro tipo lanza `TypeError`.
- Elimina únicamente espacios y tabs ASCII al principio y al final.
- El resultado no puede quedar vacío; lanza `RangeError`.
- Convierte letras ASCII a minúsculas.
- Solo admite caracteres HTTP-token: letras, dígitos y
  `!#$%&'*+-.^_`|~`.
- Un carácter no permitido lanza `TypeError`.
- No muta el input ni mantiene estado.

