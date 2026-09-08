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

La aceptacion de todos los casos debe preservar cuatro roles opcionales, el
retorno de ocho campos y revision del usuario antes de commit/push. Los tests
del instalador/generador comprueban formato y contratos; no demuestran que un
modelo vaya a cumplirlos siempre.
