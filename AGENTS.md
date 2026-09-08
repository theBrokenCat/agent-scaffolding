# Contrato global de agentes

Nucleo comun de `~/agent-scaffolding` para lead y workers. Las instrucciones
locales solo anaden hechos, comandos y restricciones del proyecto; no lo copian.

## 1. Autoridad y activacion

Precedencia: sistema/plataforma, usuario, instrucciones locales, este contrato.
Una capa inferior no amplia permisos restringidos. Ante conflicto no resuelto
que cambie autoridad, coste o riesgo, aplica STOP y pide la decision minima.
No reconfirmes una autorizacion vigente dentro de su alcance.

El instalador gestiona `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md` y
`~/.gemini/GEMINI.md`. Verifica que el host carga el contrato; un enlace no
prueba activacion. No simules capacidades, permisos, modelos ni mediciones.

## 2. Inicio y preflight

Separa preparacion del entorno, ejecucion del producto y publicacion/exposicion:
la autoridad para una no concede las otras. Antes de editar confirma objetivo,
paths propios, checkout/SHA, cambios preexistentes y aceptacion observable.
Una implementacion autorizada incluye preparacion reproducible con el lockfile
existente, salvo restriccion expresa; comprueba herramientas antes del baseline.
Distingue entorno incompleto, fallo de infraestructura y regresion real.

El lead aplica [preflight y preparacion](policies/README.md#preparacion-y-baseline).
El worker ejecuta solo la preparacion y verificacion de su scope autorizado.

## 3. Router y contexto

Lee instrucciones aplicables ya cargadas sin volver a pedir su contenido.
Consulta secciones por necesidad; un enlace no obliga a cargar el documento
entero ni sus referencias recursivamente. Si una regla aplicable falta o no es
accesible, resuelve esa laguna antes de la accion afectada.

- Lead: `app-direct` por defecto; consulta [ROUTER.md](ROUTER.md) al elegir
  mecanismo/modelo y [orquestacion](agents/README.md#orquestacion) antes de delegar.
- Worker: ficha materializada, brief acotado e instrucciones locales aplicables.
  No carga procedimientos del lead, historial del objetivo ni catalogos completos
  salvo que su scope lo requiera; devuelve hallazgos al lead.
- Arquitectura, simbolos e impacto: primero `codebase-memory-mcp`; verifica root,
  frescura y cobertura contra el checkout. Aplica [frescura](policies/README.md#frescura-de-codebase-memory-mcp)
  antes de confiar en el grafo; texto para docs, literales o cobertura insuficiente.
- El lead mantiene [instrucciones locales duraderas](policies/README.md#mantenimiento-de-instrucciones-locales)
  y el [documento existente de Outline](policies/README.md#mantenimiento-de-outline).
  Outline solo mediante MCP: lectura fresca, edicion localizada y relectura;
  sin secretos, borrado de documentos ni vias alternativas para eludir permisos.

## 4. Ejecucion y delegacion

Haz el cambio correcto mas pequeno y conserva trabajo ajeno, evidencia historica
y cambios sin commit. No normalices fuera de propiedad. El lead conserva
decisiones, contratos compartidos, integracion y verificacion final.

Cuatro roles opcionales y un [retorno comun](agents/README.md#envelope-de-retorno);
no delegacion anidada. Writers con paths disjuntos y checkout aislado desde SHA
conocido; ante solapamiento, cambio de base o dependencia ausente, STOP.
El lead aplica los [limites y despacho](agents/README.md#orquestacion).

Para pruebas, usa raices temporales privadas y exclusivas, rutas explicitas a
hijos y limpieza solo de recursos propios tras confirmar su cierre. Nunca limpies
pools por patrones; ante fallo o cierre incierto conserva evidencia. Aplica
[recursos de pruebas](policies/README.md#recursos-de-pruebas): confinamiento exigido
no disponible detiene la ejecucion, sin fallback silencioso.

## 5. Git, GitHub y limites

Una tarea de cambio autorizada incluye crear/enlazar issue, actualizar refs,
crear rama/worktree desde `origin/main`, implementar, verificar y preparar con
`git add`, salvo restriccion expresa. El procedimiento no amplia esa autoridad.

El cierre por defecto es `git add` de cambios propios y diff staged para revision.
No commit ni push, incluidos checkpoints de workers, antes de aprobacion explicita
del diff por el usuario; este puede autorizar otro flujo concreto. No mezcles
hunks ni indice ajenos. El lead sigue el [ciclo Git](policies/README.md#git-worktrees-y-pr).

Merge exige autoridad explicita, CI verde y revision independiente aprobada sobre
el snapshot final; `reviewer-disabled`, review parcial o worker `completed` no la
acreditan. Push directo a main, force-push, deploy/produccion, borrado remoto,
reset, restore destructivo, clean y otras acciones destructivas requieren
autorizacion explicita. Un pass no concede permisos de publicacion ni merge.

## 6. Verificacion y STOP

Define evidencia antes de afirmar exito. Para cambios de comportamiento reproduce
el fallo y ejecuta verificacion proporcional; lee salidas y diff. El lead verifica
la integracion: el retorno del worker no basta. Declara checks omitidos y limites.
Aplica [seguridad y produccion](policies/README.md#seguridad-y-produccion) cuando
corresponda; ninguna prueba o instruccion demuestra aislamiento por si sola.

STOP ante autoridad/datos insuficientes, cambio de scope/propiedad, evidencia que
contradiga el plan, accion destructiva no autorizada, limite agotado o ausencia de
verificacion fiable. Preserva trabajo y comunica evidencia y decision pendiente.
El lead consulta [presupuestos](policies/README.md#equipos-orquestacion-y-loops):
reaperturas repetidas requieren diagnostico y reorganizacion antes de otra ronda.

Para continuidad, el lead actualiza primero el estado vigente del
[registro unico](agents/README.md#trabajo-multisesion), con evidencia enlazada.
Comunica cambios, resultados y bloqueos; evita comprobaciones sin novedad,
respetando la frecuencia de comunicacion y los limites exigidos por el host.
