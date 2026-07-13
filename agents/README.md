# Delegación y coordinación

## Escalera y semántica

1. **Principal:** un agente conserva contexto e integra; escribe únicamente si el
   perfil base permite mutación. Es el default.
2. **Subagente:** una investigación read-only, concreta y acotada. Sin
   `orchestrated` solo puede existir uno y nunca escribe.
3. **Paralelos:** workers independientes que convergen en el lead; requieren
   `orchestrated`.
4. **Equipo coordinado:** workers que intercambian decisiones durante la tarea;
   requiere `orchestrated`.

Subagente es una delegación individual, paralelo implica independencia y equipo
implica comunicación. El único caso con dos agentes sin overlay es principal más
un subagente read-only, acotado y secuencial. Cualquier otro uso de múltiples
agentes, cualquier worker escritor que el perfil base permita, paralelo o equipo
exige `orchestrated`. El overlay no amplía autoridad: `audit + orchestrated`
admite varios workers o equipo solo read-only, nunca writers ni mutación externa.
Si el host no ofrece equipos, usa paralelo cuando se puedan independizar o
secuencial cuando no.

## Niveles y presupuesto

Una **ronda** es una revisión y su retorno. Una **pasada** es el trabajo completo
de un agente, sea descubrimiento, ejecución, revisión o integración, hasta
alcanzar el primero de sus topes de archivos, llamadas de herramienta o tiempo.
Los topes individuales se aplican a todo participante, incluido el principal o
lead.

| Nivel | Límite individual | Presupuesto agregado de la tarea |
| --- | --- | --- |
| `fast` | Principal, sin delegación: 5 archivos, 10 llamadas, 10 minutos y 12k tokens | 5 archivos únicos, 10 llamadas, 10 minutos y 12k tokens |
| `standard` | Principal: 15 archivos, 25 llamadas, 30 minutos y 32k tokens; subagente: mismos topes operativos y 12k tokens | 20 archivos únicos, 35 llamadas, 45 minutos y 40k tokens, sumando principal y subagente |
| `deep` | Lead y cada worker: 20 archivos, 40 llamadas o 45 minutos; 60k tokens para lead y 30k para cada worker; máximo tres workers | 60 archivos únicos, 120 llamadas, 90 minutos y 120k tokens, sumando lead y workers |

En todos los niveles, las revisiones de requisitos, diff y feedback de PR
comparten un presupuesto agregado máximo de dos rondas por tarea. Las
correcciones totales permitidas son: `fast` cero, `standard` una y `deep` una.
Una corrección consume ese límite y no crea otro presupuesto; su re-revisión
consume otra ronda. Al agotar el límite de rondas o de correcciones, aplica STOP,
preserva el estado y replantea antes de continuar.

`deep` solo se activa por petición explícita, riesgo justificado o cumplimiento
del umbral `orchestrated`. En el presupuesto agregado, cada archivo se cuenta una
sola vez aunque lo consulten varios participantes; llamadas y tiempo de ejecución
se acumulan entre todos.

Los tokens son el total host-reported de input y output consumido o facturable
por lead y agentes. El cap agregado manda antes que la suma de caps individuales.
El usuario solo puede cambiar estos defaults mediante una instrucción explícita
anterior al inicio de la tarea; el agente nunca los amplía automáticamente.

Lee `token_accounting` del bloque canónico definido en `AGENTS.md`. Si el bloque
falta o es inválido, trátalo como `unavailable`:

- `enforceable`: configura los caps agregado e individuales antes de lanzar.
- `observable`: comprueba el acumulado después de cada retorno y aplica STOP si
  supera el cap; no inicies nuevos despachos.
- `unavailable`: prohíbe subagentes y equipos y ejecuta una sola pasada acotada.
  Solo una autorización explícita del usuario anterior a la delegación permite
  aceptar delegación sin medición.

Al alcanzar cualquier cap individual, cierra ese agente. Al alcanzar el cap del
lead o el agregado, detén nuevos despachos y toda ejecución, preserva lo existente
y devuelve estado parcial, evidencia y trabajo pendiente. Después del cap solo
se permiten comandos mínimos de estado o cleanup seguro.

## Umbral `orchestrated`

Solo orquesta si se cumplen los tres requisitos:

1. Hay al menos dos dominios de trabajo independientes.
2. Sus escrituras son disjuntas.
3. El ahorro estimado supera el coste de coordinación e integración.

Si falla cualquiera, ejecuta secuencialmente. Empieza con los workers mínimos y
nunca más de tres; no hay delegación anidada.

## Contrato de lanzamiento

El lead declara antes de iniciar cada worker:

| Campo | Contenido obligatorio |
| --- | --- |
| Objetivo | Resultado observable |
| Scope | Incluido, excluido y autoridad |
| Archivos | Rutas o globs exclusivos de escritura y recursos shared read-only |
| Dependencias | Contratos, entradas y bloqueos |
| Base | SHA base exacto |
| Autoridad | Perfil base, overlays y confirmación de que ningún overlay amplía mutación |
| Modelo/coste | `fast`, `standard` o `deep`, cap agregado y caps individuales |
| Tokens | `token_accounting`, contador host-reported inicial y regla de STOP |
| Aislamiento | Worktree/rama del writer o confirmación read-only |
| Verificaciones | Comandos o evidencia de retorno |
| Cierre | Éxito, bloqueo o presupuesto agotado |
| Retorno | Resumen, archivos, diff, verificaciones y riesgos |

El brief contiene punteros concretos y extractos mínimos. Nunca entrega el
repositorio completo ni contexto no relacionado.

## Propiedad, aislamiento e integración

- Asigna rutas o globs de escritura exclusivos solo cuando el perfil base permita
  writers; todo recurso compartido es read-only para workers.
- Schemas, lockfiles, migrations, generated, snapshots e integración pertenecen
  exclusivamente al lead, salvo asignación única y explícita a un worker.
- Resuelve contratos compartidos primero; después los workers los consumen
  read-only.
- Cada writer usa un worktree o aislamiento equivalente y parte del SHA declarado.
  Sin worktrees o aislamiento, solo permite lectura paralela o escritura
  secuencial.
- Ante solapamiento, cambio del SHA base o conflicto de propiedad, para y avisa;
  no reasignes, mezcles ni resuelvas silenciosamente.
- El lead integra, inspecciona el diff y repite verificaciones. Después cierra
  workers y limpia recursos temporales solo tras preservar todo el trabajo.

## Escenarios de clasificación

| Escenario | Respuesta esperada |
| --- | --- |
| Typo en documentación | `solo; fast; principal; escritura documental acotada` |
| Typo o cambio mínimo en código | `software; fast; principal; pruebas proporcionales` |
| Feature normal | `software; principal; standard` |
| Audit `/improve` | `audit; standard; principal; read-only` |
| Revisión de seguridad | `audit + security; deep por riesgo; especialista read-only acotado como máximo` |
| Hotfix de producción | `software + production; deep por riesgo; principal hasta aprobación; rollback` |
| Auditoría paralela independiente | `audit + orchestrated; deep; varios workers o equipo read-only` |
| Frontend/backend independientes | `software + orchestrated; deep; paralelo solo si cumple los tres requisitos` |
