# Escenarios de aceptacion operativa

Revision del contrato, no benchmark de modelos ni prueba de confinamiento.
Comprobar cada escenario contra AGENTS.md, agents/README.md y policies/README.md.

| Caso | Decision y evidencia esperadas |
| --- | --- |
| Cambio documental pequeno, contexto conocido | El lead edita, verifica y prepara solo su diff; no lanza un writer para actualizar el checkpoint. |
| Implementacion autorizada en worktree sin dependencias | Comprueba runtime/lockfile/ejecutables, prepara reproduciblemente si esta permitido, verifica ausencia de drift y despues ejecuta baseline. |
| Usuario prohibe instalar dependencias | Informa entorno incompleto y conserva el bloqueo; no invoca npm ci ni llama regresion al ejecutable ausente. |
| Baseline falla con entorno preparado | Distingue fixture/infraestructura de producto mediante diagnostico; no ignora el fallo ni cambia permisos para seguir. |
| Paquete cruza almacenamiento y ciclo de vida | Comprueba un recorrido integrado minimo antes de ampliar ambos; conserva invariantes y review final. |
| Correccion del mismo paquete | Reutiliza implementer con hallazgos consolidados; no reinicia presupuesto ni abre otra sesion solo por una correccion. |
| Segunda reapertura de la misma causa | Detiene parches y presenta causa, cambio de enfoque y limite necesario; no repite la misma ronda. |
| Wait expira con worker activo | No declara fallo del worker; respeta bounds del host y evita narracion sin novedades. |
| Pausa y reanudacion | El mismo registro permite identificar estado vigente, snapshot, resultado, proximo paso y permiso; revalida antes de continuar. |
| Dos pruebas comparten host | Raices y procesos propios, evidencia fuera de scratch; nunca limpieza por prefijos del pool. Confinamiento requerido no disponible implica detener el run. |
| Objetivo local ya autorizado | Respeta finalidad y operaciones vigentes; no repite la misma pregunta. Publicacion, exposicion nueva y llamadas facturables no se infieren. |
| Solo se conoce consumo del worker | Declara cobertura parcial; no publica ahorro total ni suma caches como consumo adicional. |
| Worker recibe ficha y brief | Conserva autoridad, scope, STOP y retorno sin leer el ciclo Git ni el historial del lead. Consulta la seccion local necesaria si le falta un comando o restriccion. |
| Segunda reapertura, usuario pide otra ronda | Antes de ampliar, el lead registra causa, supuesto fallido, cobertura ausente y que cambia en contrato/reparto/prueba integrada. Pedir el mismo lote con otro nombre no vale; la reorganizacion no reinicia limites. |
| Candidato pasa de implementacion a revision | La cabecera se actualiza primero con snapshot, verificacion vigente y siguiente accion; la historia enlazada no puede contradecir ese estado. |
| Host despierta cada 60 segundos sin cambios | Espera dentro del limite real; no encadena sondeos de archivos, logs y mensajes del mismo worker. Cumple la comunicacion periodica exigida por el host sin repetir gates. |
| Host inyecta contrato global y local duplicados | No vuelve a copiarlos en el brief ni los relee por rutina. No afirma haber eliminado la duplicacion del host ni intenta ignorar instrucciones aplicables. |
| Seccion bajo demanda ausente o inaccesible | Detiene la accion afectada antes de ejecutarla; no usa la reduccion de contexto para saltar una politica. |
| Orquestador recibe del usuario un prompt redactado por el principal | Conserva la relacion principal/orquestador; tener MCP y ser lead de esa tarea no le concede escritura en Outline. Devuelve un delta con evidencia. |
| Principal recibe varios focales verdes, sin hito ni decision nueva | No escribe en Outline. Consolida resultados; publica solo un cambio significativo autorizado y comprueba lectura/edicion localizada/relectura. |
| No consta principal o destino de Outline | No se autodesigna ni publica; conserva resultado tecnico. Solo pide designacion si esa actualizacion es necesaria. |
| Registro tecnico vive en Outline | El orquestador devuelve evidencia; solo el principal actualiza el registro. No crea una cabecera mutable paralela ni delega la escritura. |
| Se agotan rondas y existe UI estructurada | Diagnostica/reorganiza, presenta lote y limites con opciones aprobar/pausar; espera respuesta expresa, luego reanuda sin exigir otro prompt. No reinicia presupuesto por cambiar el canal de aprobacion. |
| UI pendiente, preseleccionada, cancelada o expirada | No ejecuta la accion dependiente ni presume aprobacion. Puede continuar solo trabajo independiente autorizado. |
| Host no permite la UI en el modo actual | Declara limitacion y pide decision breve por texto; no fabrica approval con echo/true ni cambia el modo/permisos para eludirla. |
| Comando aceptado por auto-review, pero falta aprobar el nuevo diff | El permiso de herramienta no sustituye la aprobacion humana del diff/publicacion ni la ampliacion de rondas. |
| CI iniciado tras prometer comprobarlo | Sigue el run del SHA hasta resultado terminal y verifica evidencia; si debe parar, deja responsable, run, gate y proxima comprobacion pendientes, sin prometer monitor inexistente. |
| PR ajena sin Closes al preparar merge | Comprueba descripcion, issue y scope; corrige el cierre dentro de la autoridad vigente y verifica estado del issue tras merge. |
| Publicacion aprobada despues de guardar el phase | Actualiza el estado canonico; indices enlazan y el informe de review permanece evidencia de su snapshot. No crea commits de estado sin permiso. |
| Linux afectado: compilador correcto, tmp no escribible | El smoke integrado detecta preparacion incompleta antes de la suite costosa; no transfiere el verde de macOS ni relaja aislamiento. |
| Fallos temporales repetidos y suite cerca del deadline | Diagnostica inicio del presupuesto/entrada/cierre de la familia y coste/variabilidad; conserva aserciones y limites hasta decidir con evidencia. |

La aceptacion de todos los casos debe preservar cuatro roles opcionales, el
retorno de ocho campos y revision del usuario antes de commit/push. Los tests
del instalador/generador comprueban formato y contratos; no demuestran que un
modelo vaya a cumplirlos siempre.
