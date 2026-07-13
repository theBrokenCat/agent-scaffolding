# Contrato compartido de agentes

## 1. Autoridad y fuentes de verdad

Aplica las instrucciones con esta precedencia de autoridad:

1. Límites de sistema y plataforma, que ninguna otra fuente puede reemplazar.
2. Instrucciones explícitas del usuario.
3. `AGENTS.md` y reglas locales del proyecto activo.
4. Router, perfil, planes y políticas aplicables del repositorio.

Ante una contradicción, sigue la fuente de mayor prioridad y señala el conflicto.
Para acciones Git o remotas, aplica siempre la regla más restrictiva entre los
límites de sistema o plataforma, el usuario y el proyecto.

Para la fiabilidad factual, el código, las pruebas, Git, CI y el estado observado
prevalecen al describir la implementación actual. Los planes, la memoria y la
documentación histórica aportan contexto, pero no sustituyen evidencia vigente.
Indica cualquier discrepancia entre el estado observado y la documentación.

## 2. Protocolo inicial

Antes de editar:

1. Confirma objetivo, alcance, archivos permitidos y criterio de finalización.
2. Lee las instrucciones y el plan relevantes del proyecto.
3. Comprueba rama, estado de Git y cambios preexistentes; conserva trabajo ajeno.
4. Establece una línea base verificable para el comportamiento que vas a tocar.
5. Identifica riesgos, permisos necesarios y acciones irreversibles.
6. Propón un plan breve para trabajo no trivial y resuelve bloqueos reales.

No explores todo el repositorio por defecto. Amplía el contexto solo cuando la
primera pasada no permita tomar una decisión fundada.

## 3. Router

Usa el router normal solo cuando existan `ROUTER.md` y `profiles/README.md`.
Mientras falte cualquiera de los dos, aplica únicamente las reglas comunes,
trabaja con un solo agente y no actives perfiles.

Cuando ambos existan, selecciona la forma de trabajo con esta precedencia:

1. Instrucción explícita del usuario.
2. Restricciones del proyecto activo.
3. Perfil exigido por el tipo de tarea o su riesgo.
4. Perfil `software` para cambios normales de código.
5. Perfil `solo` para el resto.

Los perfiles son contratos operativos, no personajes. Activa el perfil mínimo
que cubra el riesgo. No crees archivos, roles ni procesos opcionales por
anticipado.

## 4. Contexto, MCP y Outline

Para descubrir arquitectura, símbolos, llamadas e impacto, usa primero
`codebase-memory-mcp`: `search_graph`, `trace_path`, `get_code_snippet`,
`query_graph` y `get_architecture`, en ese orden según la necesidad. Recurre a
búsqueda textual para literales, configuración, archivos no indexados o cuando
el grafo sea insuficiente.

Consulta Outline mediante sus herramientas MCP para decisiones técnicas previas,
documentación transversal y notas de despliegue. No uses accesos alternativos
para eludir permisos. Solo modifica Outline cuando el usuario lo pida de forma
explícita y la escritura MCP esté habilitada. No expongas secretos ni elimines
documentos.

Trata MCP y Outline como contexto útil. Verifica en el repositorio los detalles
de implementación importantes y registra cuando una fuente pueda estar obsoleta.

## 5. Ejecución

- Haz el cambio correcto más pequeño que satisfaga el objetivo.
- Sigue los patrones, herramientas y dependencias existentes.
- No mezcles refactors, formato o limpieza sin relación con la tarea.
- Usa APIs y formatos estructurados en lugar de manipulación textual frágil.
- Pide autorización antes de acciones destructivas, despliegues o ampliaciones
  relevantes de alcance.
- Mantén informado al usuario durante trabajo prolongado y comunica bloqueos
  con evidencia concreta.
- Completa implementación, verificación y registro del resultado antes de cerrar.

## 6. Git y GitHub

- Trabaja en una rama corta o un worktree creado desde una base acordada.
- Conserva cambios ajenos y no reviertas, limpies ni normalices fuera de alcance.
- Verifica el baseline antes de editar y revisa el diff antes de commitear.
- Busca en la instalación una línea exacta `Git publication mode: local-only` o
  `Git publication mode: autonomous-pr`. Si falta o no es válida, usa
  `local-only`.
- `local-only` no concede autorización permanente: trabaja localmente solo hasta
  donde autoricen las instrucciones vigentes y no realices acciones remotas.
- `autonomous-pr` concede autorización permanente para crear ramas y worktrees,
  crear commits lógicos con Conventional Commits en inglés, hacer push de feature
  branches y crear o actualizar draft PRs. No reconfirmes estas acciones.
- Incluso en `autonomous-pr`, prevalece cualquier restricción más estricta del
  sistema, el usuario o el proyecto.
- El push directo a `main`, force-push, merge, cualquier borrado remoto y cualquier
  acción sobre producción requieren autorización explícita.
- Limpia una rama o worktree local solo después de confirmar que el merge terminó
  y que no contienen trabajo sin integrar.
- Si el estado del árbol contradice el alcance acordado, detente antes de alterar
  trabajo ajeno.

## 7. Delegación

Esta sección solo se aplica cuando existen `ROUTER.md` y `profiles/README.md` y
el router activa un perfil que permite delegar. Durante el fallback temporal,
mantén un único agente.

Empieza con un agente. Delega solo investigación acotada o trabajo realmente
independiente. Usa ejecución paralela cuando las tareas no compartan archivos ni
dependencias; usa un equipo solo cuando los trabajadores deban comunicarse.

Antes de delegar, declara objetivo, dependencias, archivos en propiedad, rama o
worktree, entregable, verificaciones y condición de cierre. El agente principal
conserva los contratos compartidos, integra resultados y verifica por sí mismo.
Empieza los equipos con un máximo de tres trabajadores. No permitas delegación
anidada ni más trabajadores de los necesarios, y cierra todos al terminar.

## 8. Verificación

- Define qué comando o evidencia demuestra cada criterio antes de afirmar éxito.
- Para cambios de comportamiento, prueba primero el fallo y después la corrección.
- Ejecuta pruebas, linters, compilación o validaciones proporcionales al riesgo.
- Lee la salida completa, comprueba el código de salida y revisa `git diff`.
- No sustituyas evidencia fresca por confianza, memoria o el informe de otro agente.
- Si una comprobación no puede ejecutarse, indica cuál falta y el riesgo residual.

## 9. Documentación

Mantén en el repositorio el estado operativo, los contratos y las decisiones de
implementación. Usa Outline para conocimiento transversal o histórico. No copies
sesiones completas ni dupliques información sin definir una fuente canónica.

Actualiza solo la documentación afectada. Crea ADRs, runbooks, incidentes,
lecciones o tareas persistentes cuando la duración, repetición o impacto lo
justifiquen, no como ceremonia preventiva. Usa español claro; conserva nombres
técnicos y mensajes de commit en inglés.

## 10. Condiciones de parada

Detente y solicita decisión cuando:

- falten permisos, credenciales, datos o una dependencia imprescindible;
- el alcance sea ambiguo y una suposición pueda causar daño o trabajo relevante;
- aparezcan cambios ajenos que hagan insegura la integración;
- una acción requiera destruir datos, desplegar o ampliar autoridad no concedida;
- fallen tres intentos razonados de CI o dos rondas de revisión sin acuerdo;
- la evidencia contradiga el plan o no exista una verificación fiable.

Al parar, informa qué ocurrió, qué intentaste, qué evidencia tienes y cuál es la
decisión mínima necesaria para continuar. No ocultes fallos ni declares éxito
parcial como finalización completa.
