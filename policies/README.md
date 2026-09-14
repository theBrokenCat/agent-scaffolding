# Politicas operativas

Complementan [AGENTS.md](../AGENTS.md) sin conceder permisos. Este archivo
conserva procedimientos bajo demanda: el lead consulta la seccion pertinente;
los workers solo las reglas necesarias para ejecutar su brief. Autoridad y
limites esenciales permanecen en el nucleo global.

## Confirmacion y mutacion

Aplica [autoridad y preflight](../AGENTS.md#2-inicio-y-preflight).
Una herramienta disponible no implica permiso. `read-only` excluye escrituras
locales y remotas; escribir requiere scope, ownership, baseline y verificacion.

### Aprobaciones en el host

Cuando falte una decision humana, prepara primero un resultado revisable: motivo,
scope/paths, snapshot, limite concreto de correccion/review/tests y accion
solicitada. Una ampliacion de rondas requiere el diagnostico de
[loops](#equipos-orquestacion-y-loops); no es un permiso indefinido ni de publicacion.

Prefiere la UI estructurada del host a terminar pidiendo otro prompt escrito:
en Codex, `request_user_input_async` si esta disponible y sus instrucciones
permiten esa decision; otro mecanismo nativo solo si el host/modo lo admite.
Presenta opciones inequivocas, por ejemplo "Aprobar este lote" y "Mantener pausa".
La pregunta incluye el alcance y el limite, no solo "Continuar". Registra la
respuesta humana y su scope en el registro existente; no anadas otro formulario.

Una peticion asincrona no concede permiso: mantiene pendiente la accion afectada
hasta recibir la respuesta. Preseleccion, timeout, cierre del dialogo, ausencia
de respuesta o aprobacion automatica de una herramienta no equivalen al si del
usuario. Tras aprobacion explicita, retoma dentro de ese alcance sin exigir
otro mensaje; mientras esperas, continua solo trabajo independiente autorizado.
Si no hay UI compatible, informa la limitacion y pide la misma decision breve
por texto, con estado pendiente, sin presentar el objetivo como terminado.

Las aprobaciones nativas de comandos/archivos/MCP se usan para la operacion real
que el host somete a permiso. No uses comandos vacios, herramientas ajenas,
escaladas ficticias ni cambios de configuracion para fabricar un boton. Un permiso
de filesystem no aprueba rondas, diff, push ni merge; conserva sus gates humanos
cuando correspondan. Si la capa de aprobacion rechaza, no la eludas: explica la
accion y el motivo, preserva el estado y continua lo no afectado.

Referencia de capacidades (no API invocable desde este contrato):
[Codex App Server — approvals](https://learn.chatgpt.com/docs/app-server#approvals).
La UI disponible depende del host; no se cambia su harness ni su politica global.

## Git, worktrees y PR

El lead ejecuta este ciclo bajo los [gates esenciales](../AGENTS.md#5-git-github-y-limites).
Los workers no necesitan este procedimiento salvo encargo Git explicito.

1. Crea o enlaza el issue que la tarea cierra; inspecciona status, rama, remotos
   y worktrees, y conserva trabajo ajeno.
2. Ejecuta `git fetch --prune origin` y localiza el worktree limpio que posee
   `main`. Actualizalo con `pull --ff-only` solo si esta limpio.
3. Crea la rama `feat/<n>-slug` (n = numero del issue) y su worktree desde
   `origin/main`; no reutilices un checkout con cambios ni alteres el worktree de
   `main` para desarrollar.
4. Registra SHA base, preparacion y baseline antes de editar. Distingue entorno
   incompleto, infraestructura de pruebas y regresion. Prepara lo autorizado
   antes del baseline. Diagnostica fallos y corrige los de la tarea dentro de su
   scope y presupuesto; no repares defectos ajenos ni ignores el baseline. Si
   falta autoridad, aislamiento requerido o verificacion fiable, detiene solo la
   ejecucion dependiente y conserva evidencia.
5. Tras verificar, usa `git add -- <paths>` solo sobre cambios propios. Revisa
   `git diff --cached` y `git status`; no incluyas trabajo ajeno ni mezcles cambios
   preexistentes del indice. Si un archivo contiene cambios ajenos, prepara solo
   tus hunks. Presenta archivos, pruebas y rama/worktree al usuario y espera su
   revision. Conserva el worktree y los cambios staged mientras espera.
6. Tras la aprobacion explicita para commit y push, comprueba que el diff sigue
   siendo el revisado, crea commits logicos, haz push de la feature y crea o
   actualiza su draft PR (`Closes #<n>`). Si cambia el contenido aprobado, vuelve
   a presentarlo; no extiendas el permiso a cambios posteriores.
7. Ejecuta CI y revision independiente dentro de los limites de
   [estas politicas](README.md#verificacion-y-cierre), sobre el snapshot final. En cuenta
   personal no uses approval del autor: el revisor automatico va como check.
   Si esta desactivado, exige evidencia de revision independiente documentada;
   `reviewer-disabled` nunca la acredita. La puerta es CI verde Y revision
   aprobada. Si te comprometiste a comprobar CI, sigue el run del SHA publicado
   hasta resultado terminal; lee los checks requeridos y sus artefactos pertinentes.
   Un timeout de espera no es fallo del run. Si debes detenerte, deja pendiente el
   gate con run/SHA, responsable, siguiente comprobacion y condicion de reanudacion
   en el mismo registro; no prometas seguimiento automatico que no existe.
   Antes de merge, revisa titulo/cuerpo, base/head, scope y cierre del issue
   (`Closes #<n>` cuando proceda), tambien en PRs creadas por otros.
   Merge sigue siendo explicito; solo el auto-merge preautorizado lo
   cierra sin accion manual, con todos los checks requeridos en verde.
8. Confirma la integracion con `gh pr view <n> --json state,mergedAt` antes de
   limpiar: el squash merge reescribe el head y `git branch -d` puede
   no reconocerlo. Solo si `state` es `MERGED`, actualiza el main limpio con
   `pull --ff-only`, retira los worktrees limpios de la feature con
   `git worktree remove`, borra la rama local ya integrada con `git branch -D` y
   poda refs/metadatos obsoletos. El borrado remoto sigue requiriendo autorizacion.
   Comprueba el cierre del issue que la PR debia resolver y actualiza primero el
   estado canonico con merge/SHA y gates restantes. Corrige cabeceras vigentes que
   todavia pidan una aprobacion ya concedida. El cierre documental no autoriza
   otro commit ni una escritura en Outline por parte del orquestador.

Las restricciones propias de GitHub,
bootstrap, rulesets, auto-merge y checks estan en [.github/WORKFLOW.md](../.github/WORKFLOW.md).
No cambies configuracion remota ni publiques fuera de la autoridad ya concedida.

## Contexto, grafo y Outline

### Preparacion y baseline

Detecta app/CLI y capacidades reales: ejecucion, delegacion, paralelo, teams,
modelos, permisos y medicion de coste. No simules las ausentes.

Para una tarea sustancial, antes de ejecutar presenta:

```text
Recomiendo: <app-direct|app-delegated|app-parallel|cli-handoff|hybrid>
Motivo: <una frase>
La app conservara: <decisiones e integracion>
Delegare: <scope o nada>
Confirmacion necesaria: <si/no>
```

`fast` no pregunta. En `standard` o `deep`, escrituras amplias, equipos,
seguridad, produccion o relevo, pide confirmacion solo cuando la opcion propuesta
cambie coste, autoridad, superficie de escritura o destino de ejecucion. Una
instruccion explicita ya resuelve esa decision mientras no contradiga una capa
superior.


Una implementacion autorizada incluye preparar dependencias en su worktree
aislado con el lockfile existente y el comando reproducible del proyecto
(por ejemplo, `npm ci`), salvo restriccion explicita. Comprueba primero runtime,
herramientas, espacio y ejecutables locales; no lances toda la suite para
descubrir que el entorno no esta preparado. Verifica que lockfile y archivos
versionados no cambian; cualquier cambio inesperado requiere diagnostico.

Preparar dependencias no autoriza nuevas versiones, llamadas facturables ni
ejecucion contra aplicaciones. Si el entorno no puede prepararse, informa
`entorno incompleto`; un fallo del launcher o la fixture es infraestructura,
no prueba por si solo una regresion del producto. No ignores fallos ni amplies
permisos para obtener un baseline verde.

Antes de una suite costosa, comprueba un recorrido integrado pequeno en cada
entorno de ejecucion afectado/disponible: runtime/compilador/flags relevantes,
temporales escribibles, arranque y cierre de CLI/navegador/supervisor cuando el
cambio los use. Reutiliza las pruebas existentes que cubran ese recorrido; no
impongas Linux, contenedores ni un smoke nuevo a proyectos que no los necesiten.
Si una plataforma requerida no esta disponible o autorizada, declara ese gate
pendiente; el verde de otra plataforma no acredita equivalencia.
Registra duracion y margen respecto al deadline cuando sea relevante. Una base
cerca del limite exige diagnostico de coste/variabilidad, no retries ni ampliacion
de plazos automatica. No llames regresion del producto a un entorno invalido.

### Recursos de pruebas

Cada ejecucion crea una raiz temporal exclusiva con permisos privados y transmite
sus rutas explicitamente a los procesos hijos. Limpia solo recursos exactos
creados por esa ejecucion y despues de confirmar el cierre de sus procesos.
Nunca borres por patrones en pools compartidos ni limpies evidencia historica.
Ante fallo o cierre incierto conserva recursos, logs y estado para diagnostico.

Cuando el host permita confinamiento, prueba que padre e hijos no pueden escribir,
renombrar ni borrar fuera de los destinos autorizados. Si el confinamiento es un
requisito y no puede aplicarse, detiene esa ejecucion; no uses fallback silencioso.
Declara el nivel realmente probado y su alcance: un launcher puede confinar sus
tests sin confinar toda la sesion del agente. Conserva el resultado y evidencia
de cada ejecucion fuera del area temporal que se limpia.

### Frescura de codebase-memory-mcp

Antes de confiar en el grafo, comprueba `list_projects` o `index_status`, root y
cobertura. `ready` solo significa que una indexacion termino, no que sea actual.
Reindexa si falta el proyecto, el root no coincide, cambia la rama/worktree, el
indice es demasiado pequeno, hay cambios sustanciales o el grafo omite simbolos.
Ejecuta `index_repository` sobre el root actual con `persistence=false`, sin
confirmacion adicional, y repite la consulta una vez. Registra rama, SHA y estado
actual, incluidos cambios sin commit. Si sigue fallando, usa texto e informa de
la degradacion; no entres en un loop de reindexacion.

Usa `fast` para refrescos cotidianos, `moderate` para relaciones cross-file y
`full` para arquitectura o recuperar cobertura. `persistence=true` escribe un
artefacto en el repo y requiere peticion explicita.

### Mantenimiento de instrucciones locales

El lead lee las instrucciones aplicables al empezar. Relee al entregar solo las
secciones modificadas o afectadas por hechos nuevos; reutiliza lo ya vigente. Actualiza `AGENTS.md` y/o `CLAUDE.md` cuando la tarea
confirme o cambie hechos esenciales y duraderos: comandos de desarrollo/tests,
convenciones, arquitectura o restricciones del proyecto. Corrige o retira datos
obsoletos; no actualices por calendario ni anadas diarios de sesion, secretos o
detalles que ya explica el codigo. Enlaza documentacion extensa.

Registra la finalidad, el entorno y las operaciones autorizadas propias del
proyecto. Separa esos hechos vigentes de planes historicos; no conviertas una
antigua autorizacion de otro objetivo en permiso actual.

Respeta la fuente comun y los imports existentes; evita duplicar reglas entre
hosts. Crea instrucciones locales solo si hay informacion propia que conservar.
Los workers comunican los hallazgos y el lead integra la actualizacion. Incluye
estos archivos en el mismo diff para revision del usuario e indica que cambio.


### Mantenimiento de Outline

Solo el **principal designado por el usuario** mantiene el documento existente
de Outline. Es la sesion que conserva la vision global y redacta encargos para
los orquestadores, incluso cuando el usuario copia esos prompts manualmente.
Principal/orquestador describen responsabilidades entre tareas, no roles nuevos
ni modelos. Ser lead de una implementacion, recibir un prompt del usuario o
tener herramientas MCP no convierte al orquestador en principal.

Los orquestadores y workers no escriben en Outline ni delegan esa escritura.
Devuelven al principal el cambio relevante y su evidencia en el retorno/relevo
existente. El principal conserva esa responsabilidad; un cambio de responsable
solo procede por designacion expresa del usuario. Si no consta principal,
no publiques alli; conserva el resultado tecnico y pide designacion solo cuando
esa actualizacion sea necesaria. La lectura necesaria por MCP sigue permitida
dentro de la autoridad local; no se fuerza una consulta al empezar cada tarea.

El principal comprueba que proyecto/destino y permiso de escritura son explicitos
y vigentes. Una restriccion local prevalece sobre mantenimiento rutinario.
No elijas por nombre parecido ni crees otro documento/backlog automaticamente.

Publica solo cambios significativos para la vision del usuario: hito aceptado o
integrado, decision que cambie alcance/prioridades, bloqueo que requiera accion,
o comandos/requisitos de arranque o pruebas que hayan cambiado. Una ronda nueva,
un focal verde, un commit o CI en curso no bastan por si solos. Consolida varios
resultados de orquestadores en una actualizacion y no escribas por calendario,
por herramienta ni al cerrar cada tarea sin novedad significativa.

Conserva una vista breve y util para el usuario:

- Objetivo y estado: que se hace, que esta pendiente o bloqueado y por que.
- Ubicacion: proyecto y checkout/rama de trabajo cuando ayuden a retomarlo.
- Siguientes pasos: accion concreta, responsable o decision pendiente.
- Verificacion: pruebas realizadas y resultado, pruebas pendientes y comandos
  para ejecutarlas desde el directorio correcto. Distingue comprobado de previsto.
- Arranque: comandos y requisitos no secretos para lanzar el proyecto cuando
  cambien; enlaza la documentacion del repositorio si ya los explica.

Enlaza issues, PR y evidencia en vez de copiar historiales. Si Outline ya es el
registro del objetivo, actualiza ese mismo registro. Si el seguimiento detallado
vive en un issue, conserva alli ese detalle y actualiza en Outline solo el resumen
util y el enlace. No confundas implementado, staged, integrado y desplegado.

Antes de escribir, relee la version actual y modifica solo las secciones afectadas;
conserva ediciones manuales y contenido ajeno. Si la herramienta reemplaza todo el
texto, parte de esa lectura fresca y verifica que el resto se conserva. Despues,
vuelve a leer y comprueba el resultado. Publica solo hechos sustentados; marca
incertidumbres y decisiones pendientes. No incluyas secretos ni logs completos.

Si falta MCP, permiso de escritura o un destino inequívoco, informa que Outline
queda pendiente y conserva el resumen propuesto en el relevo existente. No eludas
el bloqueo ni afirmes que esta actualizado; continua el trabajo independiente
que siga autorizado. Crear, mover o reorganizar documentos requiere una peticion
especifica. La actualizacion rutinaria del documento identificado sigue la
autoridad del contrato global.

## Seguridad y produccion

Activa seguridad para autenticacion, autorizacion, permisos, secretos, exposicion,
dependencias, input no confiable o peticion explicita. Usa el skill especializado
con `domain: security`, redacta secretos y valida hallazgos antes de afirmarlos.
No existe un rol adicional: el reviewer abre el gate y no lo sustituye.
Las acciones intrusivas requieren autorizacion explicita.

Produccion exige estado observado, alcance, autorizacion para actuar, rollback
verificable y comprobacion posterior. No activa seguridad sin un trigger real y
ningun gate concede escritura. Merge y deploy son decisiones separadas.

## Equipos, orquestacion y loops

Roles, limites de concurrencia, propiedad, despacho, espera y correcciones viven
en [agents/README.md](../agents/README.md#orquestacion). Son obligatorios cuando
se delega; un enlace no convierte estas reglas en opcionales.

Presupuestos de ejecucion:

- Descubrimiento: una pasada inicial y una ampliacion con evidencia nueva.
- Cada worker: una pasada y como maximo una correccion solicitada por el lead.
- Requisitos, diff y feedback de PR: como maximo dos rondas de review.
- CI: tres intentos razonados; no repitas el mismo intento sin evidencia nueva.

Al agotar un limite, detiene nuevos despachos, preserva estado y aplica STOP. No
cambies rol, modelo, alias o formulacion para reiniciar un loop agotado: escalar
no es una via para eludir el limite. Los
budgets del brief pueden ser menores; ampliar un limite necesita nueva autoridad.
Antes de solicitarla, realiza en el registro existente el diagnostico del lead:
causa de la reapertura, supuesto del contrato que fallo, cobertura que no lo
detecto y cambio concreto de contrato, reparto o prueba integrada. Distingue
un defecto nuevo de una correccion que no cerro su causa. Define aceptacion y
presupuesto del nuevo enfoque; no solicites otra ronda equivalente solo porque
el ultimo reviewer encuentre algo mas. Reorganizar no reinicia limites ni concede
autoridad: sin ampliacion autorizada, conserva el STOP y solicita la decision
mediante [aprobaciones en el host](#aprobaciones-en-el-host), sin cerrar como exito.
Si se repiten fallos temporales, revisa en ese diagnostico la familia completa:
preparacion, inicio del presupuesto, entrada observable, deadline y cierre.
No encadenes parches de tiempos ni suites completas por cada sintoma aislado.

## Verificacion y cierre

Aplica [verificacion y STOP](../AGENTS.md#6-verificacion-y-stop). Define los checks
por cambios y riesgo; conserva los gates explicitos de cada proyecto. Un resultado
es reutilizable si codigo, configuracion y entorno relevantes no han cambiado.
No ejecutes de nuevo un test ya incluido en una suite verificada sobre ese estado.
Repite o amplia por nuevos cambios, fallos o dudas concretas. Declara checks
omitidos y riesgo residual; el lead verifica despues de integrar. El
[retorno comun](../agents/README.md#envelope-de-retorno) distingue terminar una
revision de aprobarla. CI desactivada, review parcial y falta de evidencia nunca
satisfacen un gate de revision independiente.
