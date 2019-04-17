# toolchain
Build musl libc based Linux toolchains easily.

Build process:
- Build binutils
- Build gcc stage1 (C only, static libgcc)
- Build musl stage1 (linked against static libgcc)
- Build gcc stage2 (C and C++, dynamic libgcc)
- Build musl stage2 (linked against dynamic libgcc)

## howto
Edit config.mk with your desired settings. Run `make -j <threads>`

## copying
Released under the ISC license, check `license.txt` for details.
