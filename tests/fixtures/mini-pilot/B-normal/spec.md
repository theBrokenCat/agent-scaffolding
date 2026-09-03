# B — Política normal de retry

Implementa los exports existentes en `src/backoff.mjs` y
`src/retry-policy.mjs`.

## `cappedExponentialDelay(baseMs, attempt, maxMs)`

- Los tres argumentos deben ser números finitos no negativos.
- `attempt` debe ser entero.
- Devuelve `min(maxMs, baseMs * 2 ** attempt)` sin devolver `Infinity`.
- Inputs inválidos lanzan `TypeError`.

## `evaluateRetry(input, policy)`

`input` contiene `method`, `status`, `attempt`, `maxAttempts` y opcionalmente
`retryAfterMs`. `policy` contiene `baseDelayMs`, `maxDelayMs` y `allowPost`.

- Métodos retryables: GET, HEAD, PUT y DELETE; POST solo con `allowPost=true`.
- Status retryables: 408, 429, 500, 502, 503 y 504.
- No reintenta cuando `attempt >= maxAttempts`.
- Si reintenta y `retryAfterMs` es finito y no negativo, usa ese delay limitado
  por `maxDelayMs`; si no, usa `cappedExponentialDelay`.
- Devuelve siempre `{ retry, delayMs, reason }`.
- Reasons: `method`, `status`, `exhausted` o `retry`.
- Cuando `retry=false`, `delayMs=0`.
- No muta `input` ni `policy`.

