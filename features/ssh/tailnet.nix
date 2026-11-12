# SSH client settings for the tailnet's machines, which the fleet's systems
# and CI both use. The tailnet proves who a host is, so its first key is
# trusted; an offline one fails fast.
settings: ''
  Host *.${settings.tailscale.tailnet}
    StrictHostKeyChecking accept-new
    ConnectTimeout 5
''
