# Diseño de ai-os

Decisiones acordadas con el propietario (2026-10-27) y cómo se materializan.

## Requisitos

| Requisito | Decisión |
|---|---|
| Hardware | Raspberry Pi 5, arranque desde microSD de 8-16 GB, Ethernet, ventilador activo, sin RTC |
| No corromperse al cortar la luz | Rootfs en solo lectura, `/tmp`, `/run`, `/var/*` en RAM, una única partición escribible (`/data`) con ext4 con journal |
| OTA | Pull periódico de la última **release estable** de GitHub; las pre-releases no se instalan |
| Seguridad OTA | Bundles RAUC `verity` firmados; la Pi solo acepta la firma de `keys/ca.cert.pem` |
| Fallo de actualización | Rollback automático (A/B + contador de intentos en U-Boot + watchdog) |
| Reinicio | Automático e inmediato tras instalar |
| Apps | Dentro de la imagen (solo shell por ahora). Cada cambio de app = nueva release del SO |
| Acceso | SSH solo con clave pública (Dropbear) + consola HDMI |
| Base | Buildroot 2026.02.3 (LTS), BusyBox init, kernel de Raspberry Pi |
| Build | GitHub Actions al subir un tag `vX.Y.Z` |

## Particiones de la microSD

```
p1  boot      FAT   64 MB   firmware RPi, u-boot.bin, boot.scr, uboot.env (escribible, sync)
p2  rootfs A  ext4  256 MB  solo lectura; incluye /boot/Image (kernel)
p3  rootfs B  ext4  256 MB  solo lectura
p4  data      ext4  512 MB  /data: claves SSH, estado de RAUC, estado del actualizador
```

El kernel vive **dentro** del rootfs de cada slot, así kernel y userspace se actualizan juntos de forma atómica.
La partición `boot` (firmware, U-Boot, `boot.scr`) **no** se actualiza por OTA: cambiar la lógica de arranque requiere reflashear.

## Arranque A/B

1. El firmware de la RPi5 (`config.txt`: `kernel=u-boot.bin`) carga U-Boot.
2. `boot.scr` (de `boot.cmd`) recorre `BOOT_ORDER`, descuenta `BOOT_x_LEFT` del primer slot con intentos y carga `/boot/Image` de esa partición.
3. En el userspace, `aios-markgood` espera 60 s y, si `/data` es escribible, Dropbear corre y RAUC responde, ejecuta `rauc status mark-good` (restaura los intentos del slot).
4. Si el sistema se cuelga, el watchdog (BusyBox, 10 s) reinicia; si nunca se confirma, los intentos llegan a 0 y U-Boot pasa al otro slot.
5. La red **no** cuenta como criterio de salud: desenchufar el cable no debe provocar un rollback.

## Flujo OTA

```
tag vX.Y.Z --> GitHub Actions --> build + bundle firmado --> GitHub Release
                                                                  |
Pi: aios-updater (cada 6 h + jitter) --> API releases/latest ----+
    si version > actual y no bloqueada: rauc install <url>  (streaming HTTPS)
    --> escribe el slot inactivo --> reboot --> markgood o rollback
```

- Si una versión falla y se produce rollback, el actualizador la **bloquea** (`/data/ota/blocked`) para no entrar en bucle; se desbloquea publicando una versión mayor.
- Sin RTC, la hora llega por NTP (`ntpd`). RAUC valida el certificado contra la fecha de firma del bundle (`use-bundle-signing-time`), y el actualizador espera a tener un reloj ≥ 2026 antes de hablar TLS con GitHub.

## Claves

- `keys/ca.cert.pem` (público, en el repo) se graba en la imagen.
- La clave privada vive en `~/.aios-keys/signing.key.pem` y en el secreto de Actions `RAUC_SIGNING_KEY`. **Si se pierde, hay que reflashear todas las Pi** con un certificado nuevo.
- `keys/authorized_keys` lista las claves SSH autorizadas (root). Se siembra en `/data` en el primer arranque.

## Puntos sin validar en hardware (riesgos conocidos)

El esqueleto **no se ha compilado ni probado todavía**. Hay que verificar en este orden:

1. U-Boot `rpi_arm64` arranca en la RPi5 y el SD es `mmc 0` (si no, ajustar `boot.cmd`, `uboot.fragment`).
2. `ttyAMA10` es la UART de depuración de la Pi 5 (no hace falta si solo se usa HDMI).
3. `rauc install https://...` con streaming sobre las URLs de GitHub (redirección a la CDN + Range). Plan B: descargar a `/data/ota` e instalar localmente.
4. Que `BR2_PACKAGE_RAUC_STREAMING`, `BR2_PACKAGE_BUSYBOX_WATCHDOG*` y el init script de RAUC existen con esos nombres en Buildroot 2026.02.3 (`make aios_rpi5_defconfig` los validará).
5. Que el init de RAUC (BusyBox) arranca `rauc service` antes de `aios-markgood`.

## Pendiente / futuro

- Crecer la partición `/data` hasta ocupar toda la tarjeta (hoy fija en 512 MB).
- Contraseña de root: la consola HDMI no pide contraseña (SSH sí exige clave). Decidir si se fija una.
- Hora persistente entre reinicios (`fake-hwclock`) y logs persistentes limitados.
- Actualizar el bootloader/firmware por OTA.
- Apps: runtimes (Python, etc.) o contenedores cuando se necesiten.
