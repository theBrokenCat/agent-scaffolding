# A — Normalización mecánica de header

Implementa `normalizeHeaderName(value)` en `src/header-name.mjs`.

Contrato:

- `value` debe ser string; otro tipo lanza `TypeError`.
- Elimina únicamente espacios y tabs ASCII al principio y al final.
- El resultado no puede quedar vacío; lanza `RangeError`.
- Convierte letras ASCII a minúsculas.
- Solo admite letras ASCII, dígitos y estos símbolos HTTP-token:

  ```text
  ! # $ % & ' * + - . ^ _ ` | ~
  ```
- Un carácter no permitido lanza `TypeError`.
- Llamadas repetidas o intercaladas producen el mismo resultado para el mismo
  input; la función no mantiene estado.
