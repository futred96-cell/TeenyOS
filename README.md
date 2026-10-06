# TeenyOS
An operating system made from scratch in NASM. GUI, TCP/IP, SB16 audio, and a custom naming layer.


# TeenyOS

A 32-bit x86 OS written in NASM.

## What it is

TeenyOS boots from a disk image and takes over the machine. No Linux or
Windows underneath. It has its own GUI, network stack, sound, and file
system. Made to run on old hardware with low RAM.

## Stuff it does

- Bootloader and kernel, both in NASM
- 640x480 true color screen
- Windows you can drag, resize, snap to edges
- Taskbar, start menu, alt-tab
- Terminal, Files, Notepad, Paint, Calculator, Snake, Settings
- Network driver (e1000) with ARP, IPv4, ICMP, TCP, UDP
- SB16 sound driver, plays .wav files
- Filesystem that saves stuff across reboots
- A naming layer where two TeenyOS machines can look up each other's
  names without DNS or ICANN
- Login screen, wallpaper, boot chime

## Building

You need NASM and QEMU. On Windows, just run:

    build.bat

## Running

    qemu-system-x86_64.exe -drive format=raw,file=teenyos.img -netdev user,id=n0 -device e1000,netdev=n0 -device sb16

## Status

Beta (Havent changed actual UI to beta, in UI Its still "Alpha 1.8". Tested only in QEMU. Not tested on real hardware or other
emulators yet.

Known working:
- QEMU (qemu-system-x86_64, i386 machine, e1000 NIC, sb16)

Not tested:
- VirtualBox
- VMware
- Bochs
- Real hardware

## License

MIT
