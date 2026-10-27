# ai-os

Sistema operativo mínimo (Linux + Buildroot) para **Raspberry Pi 5** que:

- **No se corrompe si se corta la luz**: rootfs de solo lectura, el resto en RAM, una única partición de datos con journal.
- **Se actualiza solo (OTA)**: la Pi consulta las releases de este repositorio, instala el bundle firmado en el slot inactivo (A/B) y reinicia. Si la nueva versión no arranca bien, vuelve sola a la anterior.

> Estado: **esqueleto inicial (v0.1.0), aún sin compilar ni probar en hardware**. Ver [docs/DISENO.md](docs/DISENO.md) para el diseño y la lista de puntos por validar.

## Estructura

```
br2-external/      Árbol externo de Buildroot (defconfig, U-Boot, overlay del rootfs, scripts de imagen)
scripts/           build.sh, make-bundle.sh, gen-keys.sh
keys/              ca.cert.pem (público) y authorized_keys (claves SSH)
docs/DISENO.md     Diseño, flujo OTA, riesgos conocidos
.github/workflows/ CI: compila y publica la release al subir un tag
VERSION            Versión base del sistema
```

## Primeros pasos

1. **Clave SSH**: añade tu clave pública a `keys/authorized_keys` (sin ella, la compilación falla a propósito).
2. **Claves de firma** (una sola vez): `./scripts/gen-keys.sh`, y sube la privada como secreto:
   `gh secret set RAUC_SIGNING_KEY < ~/.aios-keys/signing.key.pem`
3. **Publicar una versión**: `git tag v0.1.0 && git push --tags`. Actions compila y crea la release con `sdcard.img.xz` (para el primer flasheo) y `ai-os-X.Y.Z.raucb` (para el OTA).
4. **Primer flasheo**: descomprime `sdcard.img.xz` y grábalo en la microSD (Raspberry Pi Imager → "Usar personalizado", o `dd`). A partir de ahí, todo es OTA.
5. **Entrar**: `ssh root@ai-os.local` (o la IP que dé tu router) con tu clave.

Compilación local (Linux/WSL2 con las [dependencias de Buildroot](https://buildroot.org/downloads/manual/manual.html#requirement-mandatory)): `./scripts/build.sh`.

## Releases y canales

- Tag `vX.Y.Z` → release **estable**: la siguen las Pi.
- Tag `vX.Y.Z-algo` → **pre-release**: las Pi la ignoran (sirve para probar a mano con `rauc install`).

## Comandos útiles en la Pi

```
rauc status                  # slots, versión y estado de arranque
aios-updater check           # comprobar/instalar ahora
cat /etc/aios-release        # versión instalada
```
