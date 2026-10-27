# ai-os — guía para Claude

SO para Raspberry Pi 5 basado en Buildroot: rootfs de solo lectura, A/B con RAUC + U-Boot, OTA desde GitHub Releases (repo público `alexcatesp/ai-os`). Diseño completo en `docs/DISENO.md`.

## Reglas del proyecto

- Idioma: español en docs, comentarios y mensajes de commit.
- Actualizar `README.md`, `CLAUDE.md` y `docs/DISENO.md` con cada cambio relevante.
- Tras una compilación correcta: commit y push.
- Consultar dudas con AskUserQuestion; no asumir.
- Windows es el equipo de edición; **Buildroot solo compila en Linux** (CI o WSL2). Los scripts `.sh` deben tener finales de línea LF y pasar `bash -n`.

## Estructura

- `br2-external/` — árbol externo de Buildroot (`BR2_EXTERNAL_AIOS_PATH`). Defconfig: `configs/aios_rpi5_defconfig`. Todo lo específico de placa en `board/aios/rpi5/` (boot.cmd, genimage.cfg, fragmentos de kernel y U-Boot, `overlay/` = ficheros que acaban en el rootfs).
- `scripts/` — `build.sh` (clona Buildroot 2026.02.3 en `.cache/` y compila a `output/`), `make-bundle.sh` (firma el `.raucb`), `gen-keys.sh`.
- `keys/` — `ca.cert.pem` público; `authorized_keys` SSH. La clave privada de firma **nunca** va al repo (`~/.aios-keys/`, secreto `RAUC_SIGNING_KEY`).

## Convenciones y trampas

- Particiones: p1 boot FAT, p2/p3 rootfs A/B, p4 `/data`. Si cambian, tocar a la vez `genimage.cfg`, `boot.cmd`, `cmdline.txt`, `overlay/etc/fstab` y `overlay/etc/rauc/system.conf`.
- Solo `/data` es escribible de forma persistente (más `/boot` para `uboot.env`). Todo lo demás en tmpfs: cualquier servicio nuevo que escriba en disco debe usar `/data`.
- Las versiones vienen de `VERSION` o de `AIOS_VERSION` (CI la saca del tag). Se graba en `/etc/aios-release`.
- Los scripts de init (`S*aios-*`) y `usr/bin/aios-*` se marcan ejecutables en `post-build.sh` porque git en Windows no conserva el bit.
- Una versión que provoca rollback queda bloqueada en `/data/ota/blocked` hasta que salga una mayor.

## Estado

v0.1.0: esqueleto sin compilar ni probar en hardware; los riesgos pendientes de validar están listados en `docs/DISENO.md`. No afirmar que algo "funciona" hasta compilarlo en CI y probarlo en la Pi.
