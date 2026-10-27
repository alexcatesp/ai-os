#!/bin/bash
# Compila la imagen de ai-os. Requiere Linux (o WSL2) con las dependencias de Buildroot.
#   AIOS_VERSION   version a grabar en la imagen (por defecto, el fichero VERSION)
#   JOBS           procesos paralelos (por defecto, nproc)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BR_VERSION="2026.02.3"
BR_SRC="${ROOT}/.cache/buildroot-${BR_VERSION}"
OUT="${ROOT}/output"

export AIOS_VERSION="${AIOS_VERSION:-$(cat "${ROOT}/VERSION")}"
# Descargas fuera del arbol de Buildroot para poder cachearlas en CI
export BR2_DL_DIR="${OUT}/dl"

if [ ! -d "${BR_SRC}" ]; then
	mkdir -p "${ROOT}/.cache"
	git clone --depth 1 --branch "${BR_VERSION}" https://gitlab.com/buildroot.org/buildroot.git "${BR_SRC}"
fi

make -C "${BR_SRC}" O="${OUT}" BR2_EXTERNAL="${ROOT}/br2-external" aios_rpi5_defconfig
make -C "${BR_SRC}" O="${OUT}" BR2_EXTERNAL="${ROOT}/br2-external" -j"${JOBS:-$(nproc)}"

echo "Imagen lista: ${OUT}/images/sdcard.img (version ${AIOS_VERSION})"
