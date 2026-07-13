# Delegación y coordinación

## Escalera y semántica

1. **Principal:** un agente conserva contexto, escribe e integra; es el default.
2. **Subagente:** una investigación read-only, concreta y acotada. Sin
   `orchestrated` solo puede existir uno y nunca escribe.
3. **Paralelos:** workers independientes que convergen en el lead; requieren
   `orchestrated`.
4. **Equipo coordinado:** workers que intercambian decisiones durante la tarea;
   requiere `orchestrated`.

Subagente es una delegación individual, paralelo implica independencia y equipo
implica comunicación. El único caso con dos agentes sin overlay es principal más
un subagente read-only, acotado y secuencial. Cualquier otro uso de múltiples
agentes, cualquier worker escritor, paralelo o equipo exige `orchestrated`. Si el
host no ofrece equipos, usa paralelo cuando se puedan independizar o secuencial
cuando no.

## Niveles y presupuesto

Una **ronda** es un despacho con su retorno, o un feedback con su retorno. Una
**pasada** es el trabajo completo de un agente, sea descubrimiento, ejecución,
revisión o integración, hasta alcanzar el primero de sus topes de archivos,
llamadas de herramienta o tiempo. Los topes individuales se aplican a todo
participante, incluido el principal o lead.

| Nivel | Límite individual | Presupuesto agregado de la tarea |
| --- | --- | --- |
| `fast` | Principal, sin delegación: 5 archivos, 10 llamadas o 10 minutos | 5 archivos únicos, 10 llamadas o 10 minutos |
| `standard` | Principal y subagente read-only: 15 archivos, 25 llamadas o 30 minutos cada uno; una corrección y hasta dos rondas | 20 archivos únicos, 35 llamadas o 45 minutos, sumando principal y subagente |
| `deep` | Lead y cada worker: 20 archivos, 40 llamadas o 45 minutos cada uno; máximo tres workers y hasta dos rondas | 60 archivos únicos, 120 llamadas o 90 minutos, sumando lead y workers |

`deep` solo se activa por petición explícita, riesgo justificado o cumplimiento
del umbral `orchestrated`. En el presupuesto agregado, cada archivo se cuenta una
sola vez aunque lo consulten varios participantes; llamadas y tiempo de ejecución
se acumulan entre todos.

Los niveles no nombran modelos concretos. Si el host expone presupuesto de
tokens, asigna además un cap explícito a la tarea y a cada participante; gana
siempre el primer límite alcanzado. Al alcanzar un cap individual, cierra ese
agente. Al alcanzar el cap del lead o cualquier cap agregado, detén nuevos
despachos y toda ejecución, preserva lo existente y devuelve estado parcial,
evidencia y trabajo pendiente. Después del cap solo se permiten comandos mínimos
de estado o cleanup seguro. Nunca amplíes un presupuesto de forma automática.

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
| Modelo/coste | `fast`, `standard` o `deep` y cap de tokens cuando exista |
| Aislamiento | Worktree/rama del writer o confirmación read-only |
| Verificaciones | Comandos o evidencia de retorno |
| Cierre | Éxito, bloqueo o presupuesto agotado |
| Retorno | Resumen, archivos, diff, verificaciones y riesgos |

El brief contiene punteros concretos y extractos mínimos. Nunca entrega el
repositorio completo ni contexto no relacionado.

## Propiedad, aislamiento e integración

- Asigna rutas o globs de escritura exclusivos; todo recurso compartido es
  read-only para workers.
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
| Frontend/backend independientes | `software + orchestrated; deep; paralelo solo si cumple los tres requisitos` |
