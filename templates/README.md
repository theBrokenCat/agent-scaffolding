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

Antes de considerar instalado el scaffolding, registra en la documentacion local:

1. La version, tag o commit exacto del scaffolding usado como origen.
2. `Git publication mode: local-only` o
   `Git publication mode: autonomous-pr`. Si falta o no es valido, se aplica
   `local-only`.
3. `Delete merged branches: yes` o `Delete merged branches: no`. Si falta, se
   aplica `no`; esta opcion no amplia la autoridad para configurar GitHub.
4. La rama base del proyecto.
5. Los comandos exactos de `setup`, `test`, `lint`, `typecheck` y `build`; para
   cada comando inexistente, registra `no disponible`.
6. Si el proyecto afecta a produccion: `sí` o `no`.
7. El destino de la documentacion. El repositorio es siempre la fuente canonica
   para estado, implementacion, ADRs y runbooks especificos del proyecto.
   Outline se reserva para conocimiento transversal o historico y enlaza al
   documento versionado en vez de duplicarlo.

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
- la configuracion obligatoria esta completa y `.gitignore` contiene
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
3. Mantén un manifiesto dentro del registro de instalacion con cada archivo
   creado o modificado, revisa el diff y crea un commit exclusivo de instalacion.
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
