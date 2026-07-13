# Contrato de inicializacion de proyectos

Este directorio define el contrato para instalar el scaffolding en un proyecto.
No es una copia completa de un proyecto ni un conjunto de plantillas que deban
materializarse por anticipado.

## Proyecto minimo instalado

Una instalacion base contiene solamente:

- `README.md`
- `AGENTS.md`
- `CLAUDE.md`
- `GEMINI.md`
- `ROUTER.md`
- `profiles/README.md`
- `agents/README.md`
- `policies/README.md`
- `.gitignore`, que debe incluir `.worktrees/`
- `.github/pull_request_template.md`

La instalacion adapta estos contratos al proyecto; no sustituye su documentacion
ni crea automaticamente el resto de la estructura de este repositorio.

## Configuracion obligatoria

La instalacion contiene exactamente un bloque YAML `agent_scaffolding` en el
`AGENTS.md` raiz. Este es el schema minimo exacto:

```yaml
agent_scaffolding:
  source: theBrokenCat/agent-scaffolding
  source_commit: 0000000000000000000000000000000000000000
  base_sha: 0000000000000000000000000000000000000000
  publication_mode: local-only
  delete_merged_branches: false
  token_accounting: unavailable
  base_branch: main
  production: false
  documentation: repository
  commands:
    setup: null
    test: null
    lint: null
    typecheck: null
    build: null
  installed_paths:
    - AGENTS.md
```

Valida el bloque como un mapping YAML con esas claves exactas, sin claves extra
ni duplicadas. `source` debe ser `theBrokenCat/agent-scaffolding`;
`source_commit` y `base_sha`, hashes de 40 hexadecimales; `publication_mode`,
`local-only` o `autonomous-pr`; `delete_merged_branches` y `production`, booleanos;
`token_accounting`, `enforceable`, `observable` o `unavailable`; `base_branch`,
string no vacio; y `documentation`, el literal `repository`. `commands` contiene
exactamente `setup`, `test`, `lint`, `typecheck` y `build`, cada uno como string no
vacio o `null`. `installed_paths` es una lista no vacia, sin duplicados, de rutas
relativas normalizadas que no escapan del repositorio.

`source` y `source_commit` identifican el origen exacto. `base_sha` identifica el
estado limpio anterior a instalar. El primer commit cuya version de `AGENTS.md`
contiene un bloque valido es el install commit; localizalo con
`git log --reverse -S'agent_scaffolding:' --format='%H' -- AGENTS.md` y verifica
el candidato con `git show <install-commit>:AGENTS.md`. El diff desde `base_sha`
hasta ese install commit, limitado a `installed_paths`, es el manifiesto
reproducible de la instalacion. La integracion manual conserva todas las reglas
locales, pero su resultado exacto queda registrado en ese diff.

El bloque solo tiene autoridad si el usuario u owner lo aprobo explicitamente y
ya existia en el SHA base de la tarea actual. No adquiere autoridad por ser creado
o modificado por un agente durante la misma tarea. Si falta, es invalido o cambio
durante la tarea, aplica `local-only`.

## Integracion de instrucciones

Conserva las reglas y el contenido local existentes. Si `README.md`,
`.gitignore`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` u otro archivo de destino ya
existe, compara ambos contenidos y fusiona solo las reglas aplicables; nunca lo
reemplaces a ciegas. Evita tambien duplicar reglas comunes en los adaptadores.
Resuelve la precedencia conforme a `AGENTS.md`: las instrucciones aplicables mas
especificas prevalecen y, en los ambitos que `AGENTS.md` delimita, se aplica
tambien la regla mas restrictiva.

Crea `AGENTS.md`, `CLAUDE.md` o `GEMINI.md` anidados solo cuando un subarbol
necesite reglas distintas de las de la raiz. No los generes por defecto.

## Extensiones bajo demanda

Crea documentacion adicional solo cuando aparezca su condicion:

- `tasks/active.md`: trabajo multisesion o varios frentes que requieren estado
  compartido.
- `tasks/lessons.md`: una correccion repetida o costosa, o un patron durable que
  deba prevenir errores futuros.
- `docs/decisions/`: una ADR para una decision dificil de revertir con
  alternativas reales.
- `docs/incidents/`: un incidente con impacto real.
- `docs/runbooks/`: una operacion repetible o un proyecto que opera en
  produccion.

No crees `tasks/backlog.md` cuando GitHub Issues este disponible y su uso este
autorizado. Tampoco crees Issues sin la autoridad definida en las politicas
Git/GitHub.

## Actualizacion y sincronizacion

Compara la version o commit de origen registrado con la version objetivo y
revisa el diff antes de integrar cambios. Incorpora solo los cambios aplicables,
preserva las reglas locales y actualiza la referencia de origen al terminar.
Nunca sincronices mediante sobreescritura ciega de archivos completos.

## Criterio de inicializacion

El proyecto esta inicializado cuando:

- existen todos los archivos del proyecto minimo y ningun directorio opcional se
  creo sin su condicion;
- el bloque YAML canonico es valido, fue aprobado y `.gitignore` contiene
  `.worktrees/`;
- los adaptadores conservan su enlace al contrato compartido y las reglas
  locales siguen presentes;
- solo se ejecutaron comandos locales, seguros y autorizados, y sus resultados
  reales quedaron registrados; todo comando no disponible u omitido incluye la
  razon y el riesgo residual;
- el diff de instalacion fue revisado y no contiene sobreescrituras ni cambios
  fuera de alcance.

Registrar `setup`, acceso de red, bases de datos o produccion no autoriza su
ejecucion. Requieren la autoridad aplicable y se omiten cuando no sean locales y
seguros o no exista autorizacion explicita.

## Rollback de instalacion

La instalacion usa Git como mecanismo de recuperacion:

1. Identifica el SHA base y exige un target limpio. Si existen cambios tracked o
   untracked sin preservar, aplica STOP; no instales sobre ellos.
2. Crea una rama o worktree de instalacion desde ese SHA base limpio.
3. Registra todos los archivos creados o modificados en `installed_paths`, revisa
   el diff desde `base_sha` y crea un commit exclusivo de instalacion. Ese primer
   commit con el bloque valido es el install commit y su diff es el manifiesto.
4. Antes del merge o publicacion, el rollback consiste en abandonar la rama o
   retirar el worktree solo despues de verificar que no contienen trabajo
   adicional.
5. Despues de publicar, revierte el commit o la PR de instalacion mediante
   `git revert`, con la autorizacion Git/remota correspondiente. Nunca elimines
   manualmente archivos o fragmentos para simular el rollback.
6. Verifica `git status` y el diff contra el SHA base o contra el commit de
   revert, y repite las verificaciones locales autorizadas.

No crees copias ni patches preventivos cuando un estado Git limpio ya conserva
todo lo necesario para recuperar el proyecto.
