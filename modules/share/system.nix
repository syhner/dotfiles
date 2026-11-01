{
  fileSystems."/mnt/share" = {
    device = "share"; # share name
    fsType = "9p"; # filesystem protocol, 9p is usual for QEMU
    options = [
      "trans=virtio" # usual for QEMU
      "version=9p2000.L" # protocol variant with Linux extensions, commonly required for Linux guests
      "rw" # read and write access
    ];
  };
}
