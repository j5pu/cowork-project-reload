#!/bin/bash
# PreCompact: instrucciones para el resumen de la compactacion.
cat <<EOT
Al resumir, NO resumas sino que copia LITERALMENTE, en secciones propias:
1. REGLAS: todas las instrucciones, procedimientos y preferencias que el usuario ha dado, tal cual las escribio.
2. DECISIONES: cada decision tomada en la conversacion, con su motivo si se dijo.
3. PASO EN CURSO: que se estaba haciendo exactamente, que queda pendiente y que archivos se estaban usando.
Si algo de esto no esta claro en la conversacion, indicalo como "no consta" en lugar de inventarlo.
EOT
exit 0
