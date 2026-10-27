# Seleccion de slot A/B segun el protocolo de RAUC (backend uboot).
# Variables persistentes: BOOT_ORDER, BOOT_A_LEFT, BOOT_B_LEFT.
test -n "${BOOT_ORDER}" || setenv BOOT_ORDER "A B"
test -n "${BOOT_A_LEFT}" || setenv BOOT_A_LEFT 3
test -n "${BOOT_B_LEFT}" || setenv BOOT_B_LEFT 3

setenv bootargs
setenv aios_part
for BOOT_SLOT in "${BOOT_ORDER}"; do
  if test -n "${bootargs}"; then
    echo "Slot ${BOOT_SLOT} omitido (ya hay uno elegido)"
  elif test "x${BOOT_SLOT}" = "xA"; then
    if test ${BOOT_A_LEFT} -gt 0; then
      setexpr BOOT_A_LEFT ${BOOT_A_LEFT} - 1
      echo "Slot A valido, intentos restantes: ${BOOT_A_LEFT}"
      setenv aios_part 2
      setenv bootargs "root=/dev/mmcblk0p2 ro rootwait rauc.slot=A console=tty1 console=ttyAMA10,115200"
    fi
  elif test "x${BOOT_SLOT}" = "xB"; then
    if test ${BOOT_B_LEFT} -gt 0; then
      setexpr BOOT_B_LEFT ${BOOT_B_LEFT} - 1
      echo "Slot B valido, intentos restantes: ${BOOT_B_LEFT}"
      setenv aios_part 3
      setenv bootargs "root=/dev/mmcblk0p3 ro rootwait rauc.slot=B console=tty1 console=ttyAMA10,115200"
    fi
  fi
done

if test -z "${bootargs}"; then
  echo "Ningun slot valido: se reinician los intentos"
  setenv BOOT_A_LEFT 3
  setenv BOOT_B_LEFT 3
  saveenv
  reset
fi

saveenv

# El kernel viaja dentro del rootfs de cada slot (/boot/Image): se actualiza de forma atomica con el SO.
# ${fdt_addr} es el DTB que el firmware de la RPi ya ha parcheado.
ext4load mmc 0:${aios_part} ${kernel_addr_r} /boot/Image
booti ${kernel_addr_r} - ${fdt_addr}

echo "Fallo al arrancar el slot; reiniciando para probar el siguiente"
reset
