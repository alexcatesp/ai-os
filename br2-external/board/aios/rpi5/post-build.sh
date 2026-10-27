#!/bin/sh
# Ajustes sobre el rootfs antes de empaquetarlo. $1 = TARGET_DIR
set -eu

TARGET_DIR="$1"
VERSION="${AIOS_VERSION:-$(cat "${BR2_EXTERNAL_AIOS_PATH}/../VERSION")}"

# Consola HDMI en tty1
grep -qE '^tty1::' "${TARGET_DIR}/etc/inittab" || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L tty1 0 vt100 # HDMI console' "${TARGET_DIR}/etc/inittab"

# Version del sistema (la lee el actualizador OTA)
printf 'VERSION=%s\n' "${VERSION}" > "${TARGET_DIR}/etc/aios-release"

# Claves publicas SSH autorizadas (keys/authorized_keys); sin ellas no habria forma de entrar
KEYS_DIR="${BR2_EXTERNAL_AIOS_PATH}/../keys"
if ! grep -qE '^(ssh-|ecdsa-|sk-)' "${KEYS_DIR}/authorized_keys" 2>/dev/null; then
	echo "ERROR: keys/authorized_keys no contiene ninguna clave publica SSH" >&2
	exit 1
fi
mkdir -p "${TARGET_DIR}/etc/aios" "${TARGET_DIR}/etc/rauc"
install -m 0644 "${KEYS_DIR}/authorized_keys" "${TARGET_DIR}/etc/aios/authorized_keys"
# Certificado con el que RAUC verifica los bundles OTA
install -m 0644 "${KEYS_DIR}/ca.cert.pem" "${TARGET_DIR}/etc/rauc/ca.cert.pem"

# Permisos de ejecucion (el overlay no los conserva al pasar por git en Windows)
chmod 0755 "${TARGET_DIR}"/etc/init.d/S*aios-* "${TARGET_DIR}"/usr/bin/aios-*

# Puntos de montaje de las particiones fuera del rootfs
mkdir -p "${TARGET_DIR}/boot" "${TARGET_DIR}/data" "${TARGET_DIR}/run/rauc"

# Estado persistente (claves del servidor SSH y authorized_keys) en /data
rm -rf "${TARGET_DIR}/etc/dropbear" "${TARGET_DIR}/root/.ssh"
mkdir -p "${TARGET_DIR}/root"
ln -s /data/config/dropbear "${TARGET_DIR}/etc/dropbear"
ln -s /data/config/ssh "${TARGET_DIR}/root/.ssh"
