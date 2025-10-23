{ config, pkgs, ... }:

let
  unstableTarball = fetchTarball
    https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
  dotnet-combined = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnetCorePackages.sdk_6_0
    pkgs.dotnetCorePackages.sdk_7_0
  ];
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "villefort";

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  services.xserver.enable = true;

  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  services.xserver = {
    layout = "gb";
    xkbVariant = "";
  };

  console.keyMap = "uk";

  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = false;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.users.mark = {
    isNormalUser = true;
    description = "Mark";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # apps
      firefox
      vlc
      libreoffice
      unstable.freetube
      gimp
      tor-browser-bundle-bin
      signal-desktop
      deluge
      calibre
      galculator
      steam
      # utils
      yt-dlp
      zip
      unzip
      wget
      file
      inxi
      evince
      ripgrep # for neovim
      xclip # for neovim
      # programming
      neovim
      vscode.fhs
      vscodium
      git
      meld
      sqlitebrowser
      docker
      docker-compose
      gnumake
      gcc
      clang
      gdb
      unstable.go_1_21
      python3
      nodejs
      dotnet-combined
      rustc
      cargo
    ];
  };

  nix = {
  	package = pkgs.nixFlakes;
	extraOptions = ''
		experimental-features = nix-command flakes
	'';
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  	# desktop
        pkgs.xfce.xfce4-whiskermenu-plugin
	pkgs.xfce.catfish
  ];

  programs.steam = {
  	enable = true;
	remotePlay.openFirewall = true;
	dedicatedServer.openFirewall = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
