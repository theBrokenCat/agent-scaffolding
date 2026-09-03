# B — Política normal de retry

Implementa los exports existentes en `src/backoff.mjs` y
`src/retry-policy.mjs`.

## `cappedExponentialDelay(baseMs, attempt, maxMs)`

- Los tres argumentos deben ser números finitos no negativos.
- `attempt` debe ser entero.
- Devuelve `min(maxMs, baseMs * 2 ** attempt)` sin devolver `Infinity`.
- Si `baseMs=0`, devuelve 0 incluso para attempts muy grandes.
- Inputs inválidos lanzan `TypeError`.

## `evaluateRetry(input, policy)`

`input` y `policy` deben ser objetos. `input` contiene `method` string no vacío,
`status` entero, `attempt` y `maxAttempts` enteros no negativos y opcionalmente
`retryAfterMs`, número finito no negativo. `policy` contiene `baseDelayMs` y
`maxDelayMs`, números finitos no negativos, y `allowPost` boolean. Un campo
inválido lanza `TypeError`.

- Los métodos se comparan sin distinguir mayúsculas ASCII. Métodos retryables:
  GET, HEAD, PUT y DELETE; POST solo con `allowPost=true`.
- Status retryables: 408, 429, 500, 502, 503 y 504.
- No reintenta cuando `attempt >= maxAttempts`.
- Si reintenta y `retryAfterMs` es finito y no negativo, usa ese delay limitado
  por `maxDelayMs`; si no, usa `cappedExponentialDelay`.
- Devuelve siempre `{ retry, delayMs, reason }`.
- Reasons: `method`, `status`, `exhausted` o `retry`.
- La precedencia de gates/reasons es: `method`, después `status`, después
  `exhausted`; solo si pasan los tres devuelve `retry`.
- Cuando `retry=false`, `delayMs=0`.
- No muta `input` ni `policy`.
