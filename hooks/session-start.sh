#!/bin/bash
# SessionStart: la salida estandar se anade al contexto de Claude.
# $1 = startup (chat nuevo) | compact (tras compactar)

LEER_PROYECTO="Si hay una carpeta de proyecto conectada:
- Lee entero el CLAUDE.md de su raiz y sigue sus reglas.
- Lista los skills de .claude/skills/*/SKILL.md y lee de cada uno al menos su nombre y descripcion (frontmatter), para saber que existen.
- Cuando una tarea encaje con uno de esos skills, lee su SKILL.md completo antes de hacerla.
Si no hay carpeta conectada o no existen esos archivos, dilo en una linea; no inventes su contenido."

if [ "$1" = "compact" ]; then
  cat <<EOT
Ha habido compactacion. Antes de seguir, relee CLAUDE.md, y los skills si estas en un proyecto.
$LEER_PROYECTO
Despues, contrasta el resumen con lo releido. Si no puedes recuperar que se estaba haciendo o que se habia decidido, para y avisa al usuario en vez de suponer.
EOT
else
  cat <<EOT
Nuevo chat. Antes de empezar a trabajar:
$LEER_PROYECTO
EOT
fi
exit 0
