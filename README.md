# cowork-project-reload

Plugin para Claude Cowork que hace que el agente relea el `CLAUDE.md` y los skills de la carpeta del proyecto al empezar un chat y justo después de cada compactación, y que pide al resumen de la compactación que conserve reglas, decisiones y el paso en curso.

## El problema

Cuando una conversación se compacta, el historial se sustituye por un resumen. Los skills leídos a mitad de chat se pierden en ese resumen, y el agente sigue sin los procedimientos que tenía. Este plugin le ordena releerlos y le pide avisar si no puede recuperar lo que se estaba haciendo, en lugar de inventarlo.

## Qué hacen los hooks y qué cambian

El plugin es un mod con tres hooks, en `hooks/register.ts`. Se explican por separado porque el directorio pide detallar qué ve y qué cambia cada uno.

### Hook `session.compact` (línea 36 de `register.ts`)

`session.compact` es un evento que también es el nombre de una llamada: cuando Claude Code compacta la conversación, el hook ve esa llamada, y podría cambiarla. El mod **no hace esa llamada por sí mismo**; solo la intercepta cuando otro código la hace.

- **Qué ve:** el evento de compactación: quién la dispara (`trigger`), si es de un subagente (`agentId`) y las instrucciones de resumen que ya lleve (`instructions`).
- **Qué cambia:** únicamente el campo `instructions`. Le añade al final un texto fijo que pide copiar literalmente reglas, decisiones y paso en curso en secciones propias, y escribir "no consta" si algo no está claro. Si ya había instrucciones, las conserva y añade las suyas detrás.
- **Qué no toca:** ningún otro campo de la llamada, el resultado de la compactación, los mensajes ni los archivos. Ignora las compactaciones de subagentes.
- **Aviso visible:** muestra al usuario un aviso (`$.ui.toast` y `$.ui.log`) justo antes y justo después de compactar. Es solo texto en pantalla; no entra en el contexto del modelo.
- **Si falla:** el manejador `.catch` deja pasar el evento sin cambios y la compactación sigue normal.

### Hook `prompt.context` (línea 57 de `register.ts`)

`prompt.context` es un evento por el que pasan las instrucciones y el contexto que recibe el modelo.

- **Qué ve:** la lista de bloques de contexto que Claude Code va a enviar.
- **Qué cambia:** **añade un bloque** (`relecturaProyecto`) con un texto fijo. En un chat nuevo pide leer entero `CLAUDE.md`, listar los skills de `.claude/skills/*/SKILL.md` y leer completo el que encaje con la tarea. Tras una compactación pide lo mismo y, además, contrastar el resumen con lo releído y avisar al usuario si no se puede recuperar qué se hacía o qué se había decidido.
- **Qué no toca:** no modifica, quita ni reordena los bloques existentes, ni los ajustes, ni otras instrucciones.

### Hook `session.start` (línea 51 de `register.ts`)

- **Qué hace:** al empezar un chat muestra un aviso visible (`$.ui.toast` y `$.ui.log`): "CHAT NUEVO. Se pedirá leer CLAUDE.md y los skills".
- **Qué cambia:** nada. Deja pasar el evento tal cual; el aviso es solo para el usuario y no entra en el contexto del modelo.

Ningún hook hace llamadas de red, ni lee o escribe archivos, ni lee variables de entorno o ajustes, ni guarda los mensajes del usuario. Solo llaman a `$.ui.toast` y `$.ui.log` para mostrar avisos. El texto que añaden es siempre el mismo.

## Instalación

En Cowork: Personalizar → Plugins → Añadir → marketplace `j5pu/cowork-project-reload`.

En Claude Code (2.1.287 o posterior, por los mods):

```
/plugin install cowork-project-reload --marketplace j5pu/cowork-project-reload
```

## Cómo saber que funciona

Verás avisos en pantalla: un cuadro arriba a la derecha y una línea tenue en la transcripción, al empezar un chat ("CHAT NUEVO"), antes de compactar ("ANTES de compactar") y después ("DESPUES de compactar"). Después de compactar, el agente debería releer `CLAUDE.md` y los skills.

## Estado de las pruebas

- `claude plugin test`: 6 de 6 con Claude Code 2.1.299, incluida la carga real en el motor y los avisos.
- Sesión real con el plugin como mod de la organización (declarado en los ajustes gestionados): los tres avisos se disparan y el resumen de la compactación sale con las secciones REGLAS, DECISIONES y PASO EN CURSO, marcando "No consta" lo que no se sabe. **Verificado.**
- Sesión real con el plugin instalado como un usuario cualquiera en una cuenta Team o con ajustes gestionados: la guarda `cc-plugin-sec-default` salta `session.compact` y `prompt.context` (`bypassed ... tier user`) y el mod no actúa. Para esas máquinas, el administrador debe declarar el plugin en los ajustes gestionados (ver más abajo). En máquinas sin guarda debería funcionar, pero no se ha probado.
- Cowork: no se lista en el directorio (el directorio lista los mods solo para Claude Code) y no se ha verificado allí.

### Máquinas con ajustes gestionados

En `managed-settings.json`, declarar el marketplace como carpeta local y activar el plugin:

```json
{
  "extraKnownMarketplaces": {
    "cowork-project-reload": { "source": { "source": "directory", "path": "/ruta/a/cowork-project-reload" } }
  },
  "enabledPlugins": { "cowork-project-reload@cowork-project-reload": true }
}
```

## Estructura

```
.claude-plugin/plugin.json        manifiesto
.claude-plugin/marketplace.json   catálogo de un solo plugin
hooks/hooks.json                  registra el módulo
hooks/register.ts                 los tres enganches
hooks/register.test.ts            pruebas (bun test / claude plugin test)
```

## TODO: alternativa sin mod (hooks clásicos)

Pendiente por si el mod no llega a ejecutarse (por ejemplo, con plan Team o Enterprise o con ajustes gestionados, donde la guarda `cc-plugin-sec-default` salta `session.compact` y `prompt.context`). Se probó con Claude Code 2.1.299 y es lo que se haría:

- [ ] Sustituir `hooks/hooks.json` por hooks clásicos (`hooks` en lugar de `modules`) y quitar `register.ts`, `register.test.ts` y `tsconfig.json`.
- [ ] `SessionStart` con matcher `startup` y otro con `compact`, ambos llamando a un mismo script `hooks/session-start.sh startup|compact` con ruta literal bajo `${CLAUDE_PLUGIN_ROOT}` (entre comillas). Su salida estándar se añade al contexto del modelo. Con esto el agente relee `CLAUDE.md` y los skills al empezar y tras compactar. **Probado: funciona en una cuenta Team.**
- [ ] `PreCompact` solo puede bloquear (código 2); su salida no entra en el resumen. Para proteger reglas y decisiones habría que guardar un respaldo antes de compactar:
  - el script recibe `transcript_path` y `session_id`; escribiría en `.claude/precompact/<session_id>.md` (un fichero por sesión, para que dos chats no se pisen) los mensajes literales del usuario;
  - `SessionStart:compact` ordenaría consultarlo solo si el resumen no basta, dando prioridad a los mensajes más recientes y confirmando con el usuario cualquier regla dudosa;
  - filtrar claves y tokens evidentes antes de escribir. Riesgos a valorar: reglas ya cambiadas que reaparecen, datos sensibles en disco y tamaño del fichero.
- [ ] Evitar el heredoc (`cat <<EOT`) en los scripts: el directorio lo marcó como `COMMAND_SCRIPT_NOT_FOLLOWED` (retención de política, no bloquea). Usar `echo` o `printf`.
- [ ] Reescribir las pruebas (`tests/run.sh`): scripts, `hooks.json` sin `modules`, y prueba real con `--plugin-dir`, `/compact` y comprobación de que el agente recupera una regla de `CLAUDE.md`.
- [ ] Documentar en el README qué hace cada script. Una versión completa de estos hooks está en el historial de git (commit `4e9c60b`).

## Licencia

MIT.
