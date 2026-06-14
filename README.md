# cefas-sandbox-image

Build pipeline for the bootable Linux image consumed by
[`cefas-sandbox`](https://github.com/CefasDB/cefas-sandbox) and served
at `sandbox.cefasdb.com` for the **Try CefasDB** page on
[cefasdb.com/try](https://cefasdb.com/try).

The output is the smallest plausible Linux that:

- boots in V86 in ~5 seconds
- starts `cefas-server` on `127.0.0.1:8080` as PID-1's first child
- drops the user at a `/bin/sh` prompt with the `cefas` CLI on `$PATH`

The whole thing is under 30 MB gzipped over the wire.

## Output

Two artifacts land in `out/`:

| file            | purpose                                  | typical size |
| --------------- | ---------------------------------------- | ------------ |
| `bzImage`       | Linux kernel (no modules, no networking) | ~5 MB        |
| `initramfs.cpio.gz` | rootfs + busybox + cefas binaries    | ~12 MB       |

`cefas-sandbox`'s `src/boot.ts` loads both directly via V86's
`bzimage` + `initrd` options — no MBR, no partition table, no
bootloader.

## How it's assembled

```
                  ┌────────────────────────────────┐
                  │ kernel/.config (defconfig+tiny)│
  scripts/        │                                │
  build-kernel.sh ┼─►  make bzImage  ──►  out/bzImage
                  └────────────────────────────────┘

  rootfs/         ┌─────────────────────────────────────────┐
  ├─ init        │  Dockerfile (alpine:3.20 builder stage) │
  ├─ etc/        │                                         │
  └─ sbin/      ─┼─► copy busybox + cefas-server + cefas   │
                  │   ► cpio | gzip                         │
                  └────────────────────────────────┬────────┘
                                                   ▼
                                          out/initramfs.cpio.gz
```

The kernel build is pinned to a tag in `kernel/VERSION` and uses a
trimmed defconfig (`kernel/config`) that strips networking modules,
sound, and storage drivers V86 will never present.

`cefas-server` and `cefas` come from the matching tag of
`CefasDB/cefasdb-core` — `CEFAS_VERSION` selects which release to
download.

## Build

```bash
make all            # bzImage + initramfs into out/
make initramfs      # just the rootfs
make kernel         # just the kernel
make publish        # tag, sign, upload to sandbox.cefasdb.com bucket
```

Requires Docker (for the rootfs builder), `make`, `cpio`, `gzip`.

## CI

`.github/workflows/release.yml` rebuilds on tag and uploads both
artifacts to the GitHub release. The `cefas-sandbox` deploy job
downloads them by tag and copies them into `public/img/`.

## What lives in the rootfs

```
/init                        PID 1, shell script — mounts /proc /sys, starts
                             cefas-server in the background, then execs sh
/bin/busybox                 statically linked, symlinked to every applet
/usr/sbin/cefas-server       statically linked Go binary
/usr/bin/cefas               statically linked Go binary (CLI)
/etc/cefas/server.toml       tiny config — bind 127.0.0.1:8080, ./data
/etc/motd                    welcome banner with three example commands
/data/                       empty — server writes its SSTables here
```

No networking, no users, no package manager, no /dev/sd*. The VM is
intentionally throwaway.
