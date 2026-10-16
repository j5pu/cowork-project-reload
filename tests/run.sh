#!/bin/bash
# Pruebas de los hooks. Uso: tests/run.sh [ruta-al-binario-claude]
# 1) Pruebas de los scripts (sin Claude). 2) Con binario: prueba real en un proyecto temporal.
set -u
R="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok()  { echo "ok   - $1"; }
bad() { echo "FALLA - $1"; fail=1; }

# --- 1. Scripts ---
out=$("$R/hooks/session-start.sh" startup)
[[ "$out" == *"Nuevo chat"* && "$out" == *"CLAUDE.md"* && "$out" == *".claude/skills"* ]] && ok "startup pide leer CLAUDE.md y skills" || bad "startup"
out=$("$R/hooks/session-start.sh" compact)
[[ "$out" == *"Ha habido compactacion"* && "$out" == *"para y avisa"* ]] && ok "compact pide releer y avisar si no se recupera" || bad "compact"
out=$("$R/hooks/pre-compact.sh"); rc=$?
[[ $rc -eq 0 && "$out" == *"REGLAS"* && "$out" == *"DECISIONES"* && "$out" == *"PASO EN CURSO"* ]] && ok "pre-compact sale con 0 y emite las 3 secciones" || bad "pre-compact"
python3 -c "import json; d=json.load(open('$R/hooks/hooks.json')); assert 'hooks' in d and 'modules' not in d" && ok "hooks.json es de hooks clasicos, sin modules" || bad "hooks.json"
[[ ! -e "$R/hooks/register.ts" ]] && ok "no hay codigo de mod" || bad "queda register.ts"

# --- 2. Prueba real (opcional) ---
C="${1:-}"
if [[ -n "$C" ]]; then
  T=$(mktemp -d); cd "$T" || exit 1
  printf 'Regla de prueba: la palabra clave de este proyecto es PINGUINO-42.\n' > CLAUDE.md
  S=$(uuidgen | tr A-Z a-z)
  "$C" -p --session-id "$S" --plugin-dir "$R" --debug-file "$T/d1.log" "Di solo: ok" </dev/null >/dev/null 2>&1
  grep -q "SessionStart:startup" "$T/d1.log" && grep -q "session-start.sh" "$T/d1.log" && ok "real: SessionStart:startup se ejecuta" || bad "real: startup no se ejecuto"
  "$C" -p --resume "$S" --plugin-dir "$R" --debug-file "$T/d2.log" "/compact" </dev/null >/dev/null 2>&1
  grep -q "PreCompact" "$T/d2.log" && grep -q "pre-compact.sh" "$T/d2.log" && ok "real: PreCompact se ejecuta" || bad "real: PreCompact no se ejecuto"
  grep -q "SessionStart:compact" "$T/d2.log" && ok "real: SessionStart:compact se ejecuta" || bad "real: compact no se ejecuto"
  R2=$("$C" -p --resume "$S" --plugin-dir "$R" "Despues de la compactacion: ¿cual es la palabra clave del proyecto segun CLAUDE.md? Responde solo la palabra." </dev/null 2>&1 | tail -3)
  [[ "$R2" == *PINGUINO-42* ]] && ok "real: tras compactar el agente recupera la regla de CLAUDE.md" || bad "real: no recupero la regla (respuesta: $R2)"
  echo "Directorio de prueba: $T (borralo cuando no lo necesites)"
fi
exit $fail
