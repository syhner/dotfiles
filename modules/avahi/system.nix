{
  ...
}:
{
  # Avahi for .local hostname discovery on machines that participate in a
  # local network.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      workstation = true;
    };
  };
}
