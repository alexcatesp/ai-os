#!/bin/bash
# Empaqueta y firma el bundle OTA (.raucb) a partir de output/images/rootfs.ext4.
#   RAUC_KEY, RAUC_CERT   rutas a la clave privada y al certificado de firma
#   AIOS_VERSION          version del bundle (por defecto, el fichero VERSION)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/output"
VERSION="${AIOS_VERSION:-$(cat "${ROOT}/VERSION")}"
: "${RAUC_KEY:?Falta RAUC_KEY}"
: "${RAUC_CERT:?Falta RAUC_CERT}"

RAUC="${OUT}/host/bin/rauc"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

cp "${OUT}/images/rootfs.ext4" "${WORK}/rootfs.ext4"
cat > "${WORK}/manifest.raucm" <<EOF
[update]
compatible=ai-os-rpi5
version=${VERSION}

[bundle]
format=verity

[image.rootfs]
filename=rootfs.ext4
EOF

BUNDLE="${OUT}/images/ai-os-${VERSION}.raucb"
rm -f "${BUNDLE}"
"${RAUC}" bundle --cert="${RAUC_CERT}" --key="${RAUC_KEY}" "${WORK}" "${BUNDLE}"
echo "Bundle firmado: ${BUNDLE}"
