@AGENTS.md

# Adaptador de Gemini CLI

## Memoria y contexto jerárquico

- Ejecuta `/memory show` para comprobar que el contrato común y el contexto local
  esperado forman parte de la memoria activa.
- Ejecuta `/memory reload` cuando cambien los archivos de instrucciones o el
  contexto cargado esté incompleto u obsoleto.
- Respeta el contexto jerárquico: combina las instrucciones generales con las más
  cercanas al directorio de trabajo y aplica la precedencia de `AGENTS.md`.

## Relevo de capacidades

Cuando falte una capacidad necesaria, no la simules ni omitas silenciosamente el
trabajo. Prepara un relevo con objetivo, evidencia, intentos realizados, estado
actual y verificación pendiente, y solicita al usuario el destino adecuado. Crea
una issue o tarea solo cuando exista una autorización permanente aplicable o el
usuario conceda permiso explícito.
