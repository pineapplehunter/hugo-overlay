# hugo-overlay
[![CI](https://github.com/pineapplehunter/hugo-overlay/actions/workflows/ci.yml/badge.svg)](https://github.com/pineapplehunter/hugo-overlay/actions/workflows/ci.yml)

_Pure and reproducible_ packaging of binary distributed hugo.
This overlay provides almost all versions of hugo.
The repo is inspired by [rust-overlay](https://github.com/oxalica/rust-overlay).

Features:

- Packaged almost all versions of hugo
- `extended` and `extended_withdeploy` as separate packages
- `latest` points to the latest released hugo version
- latest version is checked to build on CI

## Installation

### Classic Nix overlay

You can put the code below into your `~/.config/nixpkgs/overlays.nix`.
```nix
[ (import (builtins.fetchTarball "https://github.com/pineapplehunter/hugo-overlay/archive/main.tar.gz")) ]
```
Then the provided attribute paths are available in nix command.
```bash
$ nix-env -iA nixpkgs.hugo-bin.latest.default # `nixpkgs` (or `nixos`) is your nixpkgs channel name.
```

Alternatively, you can install it into nix channels.
```bash
$ nix-channel --add https://github.com/pineapplehunter/hugo-overlay/archive/main.tar.gz hugo-overlay
$ nix-channel --update
```
And then feel free to use it anywhere like
`import <nixpkgs> { overlays = [ (import <hugo-overlay>) ]; }` in your nix shell environment.

### Nix Flakes

**Warning: Only the output `overlay`/`overlays` are currently stable. Use other outputs at your own risk!**

For a quick play, just use `nix shell` to bring the latest hugo into scope.
(All commands below requires preview version of Nix with flake support.)
```shell
$ nix shell github:pineapplehunter/hugo-overlay
$ hugo version # This is only an example. You may get a newer version here.
hugo v0.148.1-98ba786f2f5dca0866f47ab79f394370bcb77d2f linux/amd64 BuildDate=2025-07-11T12:56:21Z VendorInfo=gohugoio
```

#### Use in NixOS Configuration

Here's an example of using it in nixos configuration.
```nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hugo-overlay = {
      url = "github:pineapplehunter/hugo-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, hugo-overlay, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # Your system configuration.
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ hugo-overlay.overlays.default ];
            environment.systemPackages = [ pkgs.hugo-bin.latest.default ];
          })
        ];
      };
    };
  };
}
```

#### Use in `devShell` for `nix develop`

Running `nix develop` will create a shell with the latest hugo installed:

```nix
{
  description = "A devShell example";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    hugo-overlay.url = "github:pineapplehunter/hugo-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, hugo-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import hugo-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      {
        devShells.default = with pkgs; mkShell {
          buildInputs = [
            openssl
            pkg-config
            eza
            fd
            hugo-bin.latest.default
          ];

          shellHook = ''
            alias ls=eza
            alias find=fd
          '';
        };
      }
    );
}

```

## Cheat sheet: common usage of `hugo-bin`

- Latest stable or older hugo profile.

```nix
hugo-bin.latest.default # latest version
hugo-bin.latest.extended # latest extended version
hugo-bin.latest.extended_withdeploy # latest extended and withdeploy version
hugo-bin."0.124.1".default # use an older version
```
