#!/bin/bash
# Genera el par de claves de firma de los bundles OTA.
#   - Clave privada -> fuera del repo (por defecto ~/.aios-keys/signing.key.pem). NUNCA se sube.
#   - Certificado   -> keys/ca.cert.pem (publico; se graba en la imagen y verifica los bundles)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEY_DIR="${1:-${HOME}/.aios-keys}"

if [ -e "${KEY_DIR}/signing.key.pem" ] || [ -e "${ROOT}/keys/ca.cert.pem" ]; then
	echo "Ya existen claves; no se sobrescriben (borralas a mano si de verdad quieres rotarlas)." >&2
	exit 1
fi

mkdir -p "${KEY_DIR}"
chmod 700 "${KEY_DIR}"
# En Git Bash (Windows) openssl es nativo: hay que pasarle rutas de Windows y evitar que
# MSYS convierta el /O=... del subject en una ruta.
to_native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
MSYS_NO_PATHCONV=1 openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 \
	-subj "/O=ai-os/CN=ai-os OTA signing" \
	-addext "keyUsage=digitalSignature" \
	-keyout "$(to_native "${KEY_DIR}/signing.key.pem")" -out "$(to_native "${ROOT}/keys/ca.cert.pem")"
chmod 600 "${KEY_DIR}/signing.key.pem"

echo "Clave privada : ${KEY_DIR}/signing.key.pem"
echo "Certificado   : ${ROOT}/keys/ca.cert.pem"
echo "Siguiente paso: gh secret set RAUC_SIGNING_KEY < ${KEY_DIR}/signing.key.pem"
