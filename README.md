# cowork-project-reload

Plugin para Claude Cowork que hace que el agente relea el `CLAUDE.md` y los skills de la carpeta del proyecto al empezar un chat y justo después de cada compactación, y que pide al resumen de la compactación que conserve reglas, decisiones y el paso en curso.

## El problema

Cuando una conversación se compacta, el historial se sustituye por un resumen. Los skills leídos a mitad de chat se pierden en ese resumen, y el agente sigue sin los procedimientos que tenía. Este plugin le ordena releerlos y le pide avisar si no puede recuperar lo que se estaba haciendo, en lugar de inventarlo.

## Qué hacen los hooks y qué cambian

El plugin es un mod con dos hooks, en `hooks/register.ts`. Se explican por separado porque el directorio pide detallar qué ve y qué cambia cada uno.

### Hook `session.compact` (línea 29 de `register.ts`)

`session.compact` es un evento que también es el nombre de una llamada: cuando Claude Code compacta la conversación, el hook ve esa llamada, y podría cambiarla. El mod **no hace esa llamada por sí mismo**; solo la intercepta cuando otro código la hace.

- **Qué ve:** el evento de compactación: quién la dispara (`trigger`), si es de un subagente (`agentId`) y las instrucciones de resumen que ya lleve (`instructions`).
- **Qué cambia:** únicamente el campo `instructions`. Le añade al final un texto fijo que pide copiar literalmente reglas, decisiones y paso en curso en secciones propias, y escribir "no consta" si algo no está claro. Si ya había instrucciones, las conserva y añade las suyas detrás.
- **Qué no toca:** ningún otro campo de la llamada, el resultado de la compactación, los mensajes ni los archivos. Ignora las compactaciones de subagentes.
- **Si falla:** el manejador `.catch` deja pasar el evento sin cambios y la compactación sigue normal.

### Hook `prompt.context` (línea 40 de `register.ts`)

`prompt.context` es un evento por el que pasan las instrucciones y el contexto que recibe el modelo.

- **Qué ve:** la lista de bloques de contexto que Claude Code va a enviar.
- **Qué cambia:** **añade un bloque** (`relecturaProyecto`) con un texto fijo. En un chat nuevo pide leer entero `CLAUDE.md`, listar los skills de `.claude/skills/*/SKILL.md` y leer completo el que encaje con la tarea. Tras una compactación pide lo mismo y, además, contrastar el resumen con lo releído y avisar al usuario si no se puede recuperar qué se hacía o qué se había decidido.
- **Qué no toca:** no modifica, quita ni reordena los bloques existentes, ni los ajustes, ni otras instrucciones.

Ninguno de los dos hooks hace llamadas de red, ni lee o escribe archivos, ni lee variables de entorno o ajustes, ni guarda los mensajes del usuario. El texto que añaden es siempre el mismo.

## Instalación

En Cowork: Personalizar → Plugins → Añadir → marketplace `j5pu/cowork-project-reload`.

En Claude Code (2.1.287 o posterior, por los mods):

```
/plugin install cowork-project-reload --marketplace j5pu/cowork-project-reload
```

## Estado de las pruebas

- `claude plugin test` pasa 4 de 4 con Claude Code 2.1.299, incluida la carga real en el motor (el bloque llega al contexto).
- Carga en una sesión real con el plugin instalado: el módulo se carga y se admite (`loaded; events: session.compact, prompt.context`).
- **Sin verificar:** en la sesión real, el log mostró `bypassed by cc-plugin-sec-default (tier user)` para ambos eventos y el resumen salió con la estructura estándar, sin las secciones REGLAS / DECISIONES / PASO EN CURSO. No está demostrado todavía que el mod modifique el resumen en una sesión real.
- No verificado dentro de Cowork.

## Estructura

```
.claude-plugin/plugin.json        manifiesto
.claude-plugin/marketplace.json   catálogo de un solo plugin
hooks/hooks.json                  registra el módulo
hooks/register.ts                 los dos enganches
hooks/register.test.ts            pruebas (bun test / claude plugin test)
```

## Licencia

MIT.
