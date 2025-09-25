{
  description = "A flake for nightly builds of the COSMIC desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # COSMIC DE Components
    cosmic-applets-src = {
      url = "github:pop-os/cosmic-applets";
      flake = false;
    };
    cosmic-applibrary-src = {
      url = "github:pop-os/cosmic-applibrary";
      flake = false;
    };
    cosmic-bg-src = {
      url = "github:pop-os/cosmic-bg";
      flake = false;
    };
    cosmic-comp-src = {
      url = "github:pop-os/cosmic-comp";
      flake = false;
    };
    cosmic-edit-src = {
      url = "github:pop-os/cosmic-edit";
      flake = false;
    };
    cosmic-files-src = {
      url = "github:pop-os/cosmic-files";
      flake = false;
    };
    cosmic-greeter-src = {
      url = "github:pop-os/cosmic-greeter";
      flake = false;
    };
    cosmic-icons-src = {
      url = "github:pop-os/cosmic-icons";
      flake = false;
    };
    cosmic-idle-src = {
      url = "github:pop-os/cosmic-idle";
      flake = false;
    };
    cosmic-launcher-src = {
      url = "github:pop-os/cosmic-launcher";
      flake = false;
    };
    cosmic-notifications-src = {
      url = "github:pop-os/cosmic-notifications";
      flake = false;
    };
    cosmic-osd-src = {
      url = "github:pop-os/cosmic-osd";
      flake = false;
    };
    cosmic-panel-src = {
      url = "github:pop-os/cosmic-panel";
      flake = false;
    };
    cosmic-player-src = {
      url = "github:pop-os/cosmic-player";
      flake = false;
    };
    cosmic-protocols-src = {
      url = "github:pop-os/cosmic-protocols";
      flake = false;
    };
    cosmic-randr-src = {
      url = "github:pop-os/cosmic-randr";
      flake = false;
    };
    cosmic-screenshot-src = {
      url = "github:pop-os/cosmic-screenshot";
      flake = false;
    };
    cosmic-session-src = {
      url = "github:pop-os/cosmic-session";
      flake = false;
    };
    cosmic-settings-src = {
      url = "github:pop-os/cosmic-settings";
      flake = false;
    };
    cosmic-settings-daemon-src = {
      url = "github:pop-os/cosmic-settings-daemon";
      flake = false;
    };
    cosmic-store-src = {
      url = "github:pop-os/cosmic-store";
      flake = false;
    };
    cosmic-term-src = {
      url = "github:pop-os/cosmic-term";
      flake = false;
    };
    cosmic-wallpapers-src = {
      url = "github:pop-os/cosmic-wallpapers";
      flake = false;
    };
    cosmic-workspaces-epoch-src = {
      url = "github:pop-os/cosmic-workspaces-epoch";
      flake = false;
    };
    xdg-desktop-portal-cosmic-src = {
      url = "github:pop-os/xdg-desktop-portal-cosmic";
      flake = false;
    };
  };

  outputs = inputs: {
    overlays.default =
      final: prev:
      let
        pkgs = prev; # Use the package set being overlaid
        lib = pkgs.lib;

        # A wrapper script to intercept a problematic git command used by vergen.
        git-wrapper = pkgs.writeShellScriptBin "git" ''
          #!${pkgs.runtimeShell}
          # When vergen runs its specific check to see if it's in a git repo...
          if [ "$*" = "rev-parse --is-inside-work-tree" ]; then
            # ...we lie and tell it "yes" so the build can continue.
            echo "true"
            exit 0
          fi
          # For all other git commands, we execute the real git program.
          exec ${pkgs.git}/bin/git "$@"
        '';

        # A helper function to create an override for a single package.
        # It takes the nixpkgs derivation name and the corresponding flake input.
        mkCosmicOverride =
          {
            pkgName,
            flakeInput,
            pkgHash ? null,
            extraBuildInputs ? [ ],
            extraNativeBuildInputs ? [ ],
            patches ? null,
            postPatch ? null,
            extraEnv ? { },
          }:
          prev.${pkgName}.overrideAttrs (
            oldAttrs:
            {
              # This is the core of the overlay: replace the source attribute
              # with the fetched source from the dedicated flake input.
              src = flakeInput;

              env =
                (oldAttrs.env or { })
                // {
                  VERGEN_GIT_SHA = flakeInput.rev;
                }
                // extraEnv;

              cargoHash = pkgHash;
              buildInputs = (oldAttrs.buildInputs or [ ]) ++ extraBuildInputs;
              nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ extraNativeBuildInputs;

              cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                inherit (final.${pkgName}) pname src version;
                hash = final.${pkgName}.cargoHash;
              };

              version = "git-${builtins.substring 0 8 flakeInput.rev}";
            }
            // lib.optionalAttrs (patches != null) { inherit patches; }
            // lib.optionalAttrs (postPatch != null) { inherit postPatch; }
          );

        mkCosmicFetchOverride =
          {
            pkgName,
            flakeInput,
          }:
          prev.${pkgName}.overrideAttrs (oldAttrs: {
            src = flakeInput;
            version = "git-${builtins.substring 0 8 flakeInput.rev}";
          });
      in
      {
        # Apply the override to each COSMIC component.
        cosmic-applets = mkCosmicOverride {
          pkgName = "cosmic-applets";
          flakeInput = inputs.cosmic-applets-src;
          pkgHash = "sha256-RnkyIlTJMxMGu+EsmZwvSIapSqdng+t8bqMVsDXprlU=";
          extraBuildInputs = [
            pkgs.pipewire
            pkgs.llvmPackages.libclang
          ];
          extraNativeBuildInputs = [ pkgs.rustPlatform.bindgenHook ];
          extraEnv = {
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          };
          patches = [ ];
        };
        cosmic-applibrary = mkCosmicOverride {
          pkgName = "cosmic-applibrary";
          flakeInput = inputs.cosmic-applibrary-src;
          pkgHash = "sha256-f5uMgscentTlcPXFSan1kKcKh1nk88/3kQPTSuc0wz4=";
        };
        cosmic-bg = mkCosmicOverride {
          pkgName = "cosmic-bg";
          flakeInput = inputs.cosmic-bg-src;
          pkgHash = "sha256-+NkraWjWHIMIyktAUlp3q2Ot1ib1QRsBBvfdbr5BXto=";
        };
        cosmic-comp = mkCosmicOverride {
          pkgName = "cosmic-comp";
          flakeInput = inputs.cosmic-comp-src;
          pkgHash = "sha256-Jaw2v+02lA5wWRAhRNW/lcLnTI7beJIZ43dqcJ60EP0=";
        };
        cosmic-edit = mkCosmicOverride {
          pkgName = "cosmic-edit";
          flakeInput = inputs.cosmic-edit-src;
          pkgHash = "sha256-YfD06RAQPZRwapd0fhNsZ0tx+0JMNDXiPJIWwDhmG0M=";
          extraBuildInputs = [ pkgs.glib ];
          extraNativeBuildInputs = [ git-wrapper ];
        };
        cosmic-files = mkCosmicOverride {
          pkgName = "cosmic-files";
          flakeInput = inputs.cosmic-files-src;
          pkgHash = "sha256-7RANj+aXdmBVO66QDgcNrrU4qEGK4Py4+ZctYWU1OO8=";
        };
        cosmic-greeter = mkCosmicOverride {
          pkgName = "cosmic-greeter";
          flakeInput = inputs.cosmic-greeter-src;
          pkgHash = "sha256-qioWGfg+cMaRNX6H6IWdcAU2py7oq9eNaxzKWw0H4R4=";
        };
        cosmic-icons = mkCosmicFetchOverride {
          pkgName = "cosmic-icons";
          flakeInput = inputs.cosmic-icons-src;
        };
        cosmic-idle = mkCosmicOverride {
          pkgName = "cosmic-idle";
          flakeInput = inputs.cosmic-idle-src;
          pkgHash = "sha256-iFR0kFyzawlXrWItzFQbG/tKGd3Snwk/0LYkPzCkJUQ=";
        };
        cosmic-launcher = mkCosmicOverride {
          pkgName = "cosmic-launcher";
          flakeInput = inputs.cosmic-launcher-src;
          pkgHash = "sha256-57rkCufJPWm844/iMIfULfaGR9770q8VgZgnqCM57Zg=";
        };
        cosmic-notifications = mkCosmicOverride {
          pkgName = "cosmic-notifications";
          flakeInput = inputs.cosmic-notifications-src;
          pkgHash = "sha256-CL8xvj57yq0qzK3tyYh3YXh+fM4ZDsmL8nP1mcqTqeQ=";
        };
        cosmic-osd = mkCosmicOverride {
          pkgName = "cosmic-osd";
          flakeInput = inputs.cosmic-osd-src;
          pkgHash = "sha256-YcNvvK+Zf8nSS5YjS5iaoipogstiyBdNY7LhWPsz9xQ=";
          extraBuildInputs = [
            pkgs.pipewire
            pkgs.libinput
            pkgs.llvmPackages.libclang
          ];
          extraNativeBuildInputs = [ pkgs.rustPlatform.bindgenHook ];
          extraEnv = {
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          };
          postPatch = "";
        };
        cosmic-panel = mkCosmicOverride {
          pkgName = "cosmic-panel";
          flakeInput = inputs.cosmic-panel-src;
          pkgHash = "sha256-8KOl581VmsfE7jiVFXy3ZDIfAqnaJuiDd7paqiFI/mk=";
        };
        cosmic-player = mkCosmicOverride {
          pkgName = "cosmic-player";
          flakeInput = inputs.cosmic-player-src;
          pkgHash = "sha256-DodFIfthiGFSvXWfPsPjFhNY6G7z3lb6pfc5HtUXhMo=";
        };
        cosmic-protocols = mkCosmicFetchOverride {
          pkgName = "cosmic-protocols";
          flakeInput = inputs.cosmic-protocols-src;
        };
        cosmic-randr = mkCosmicOverride {
          pkgName = "cosmic-randr";
          flakeInput = inputs.cosmic-randr-src;
          pkgHash = "sha256-tkmBthh+nM3Mb9WoSjxMbx3t0NTf6lv91TwEwEANS6U=";
        };
        cosmic-screenshot = mkCosmicOverride {
          pkgName = "cosmic-screenshot";
          flakeInput = inputs.cosmic-screenshot-src;
          pkgHash = "sha256-O8fFeg1TkKCg+QbTnNjsH52xln4+ophh/BW/b4zQs9o=";
        };
        cosmic-session = mkCosmicOverride {
          pkgName = "cosmic-session";
          flakeInput = inputs.cosmic-session-src;
          pkgHash = "sha256-bo46A7hS1U0cOsa/T4oMTKUTjxVCaGuFdN2qCjVHxhg=";
        };
        cosmic-settings = mkCosmicOverride {
          pkgName = "cosmic-settings";
          flakeInput = inputs.cosmic-settings-src;
          pkgHash = "sha256-dHyUTV5txSLWEDE7Blplz8CBvyuUmYNNr1kbifujHKk=";
        };
        cosmic-settings-daemon = mkCosmicOverride {
          pkgName = "cosmic-settings-daemon";
          flakeInput = inputs.cosmic-settings-daemon-src;
          pkgHash = "sha256-1YQ7eQ6L6OHvVihUUnZCDWXXtVOyaI1pFN7YD/OBcfo=";
          extraBuildInputs = [ pkgs.openssl ];
        };
        cosmic-store = mkCosmicOverride {
          pkgName = "cosmic-store";
          flakeInput = inputs.cosmic-store-src;
          pkgHash = "sha256-xdNYQB/zmndnMAkstwJ6Z2uk0fXli3gIYHchUq/3u6k=";
        };
        cosmic-term = mkCosmicOverride {
          pkgName = "cosmic-term";
          flakeInput = inputs.cosmic-term-src;
          pkgHash = "sha256-mpuVSHb9YcDZB+eyyD+5ZNzUeEgx8T25IFjsD/Q/quU=";
        };
        cosmic-wallpapers = mkCosmicFetchOverride {
          pkgName = "cosmic-wallpapers";
          flakeInput = inputs.cosmic-wallpapers-src;
        };
        cosmic-workspaces-epoch = mkCosmicOverride {
          pkgName = "cosmic-workspaces-epoch";
          flakeInput = inputs.cosmic-workspaces-epoch-src;
          pkgHash = "sha256-BE6s2dmbgXlFXrtd8b9k2LltLnegLzWbIUlaEQvv+5o=";
        };
        xdg-desktop-portal-cosmic = mkCosmicOverride {
          pkgName = "xdg-desktop-portal-cosmic";
          flakeInput = inputs.xdg-desktop-portal-cosmic-src;
          pkgHash = "sha256-uJKwwESkzqweM4JunnMIsDE8xhCyjFFZs1GiJAwnbG8=";
        };
      };
    packages = {
      x86_64-linux =
        let
          nixpkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            overlays = [ inputs.self.overlays.default ];
          };
          pkgs = {
            inherit (nixpkgs)
              cosmic-applets
              cosmic-applibrary
              cosmic-bg
              cosmic-comp
              cosmic-edit
              cosmic-files
              cosmic-greeter
              cosmic-idle
              cosmic-launcher
              cosmic-notifications
              cosmic-osd
              cosmic-panel
              cosmic-player
              cosmic-protocols
              cosmic-randr
              cosmic-screenshot
              cosmic-session
              cosmic-settings
              cosmic-settings-daemon
              cosmic-store
              cosmic-term
              cosmic-workspaces-epoch
              xdg-desktop-portal-cosmic
              ;
          };
        in
        (
          pkgs
          // {
            default = nixpkgs.linkFarmFromDrvs "cosmic-nighty-bundle" (builtins.attrValues pkgs);
          }
        );
    };
  };
}
