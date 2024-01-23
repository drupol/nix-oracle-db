# Oracle Database on Nix

The goal of this project is to provide a Nix flake that can be used to build
and use Oracle Database on Nix.

Once the flake is in a working state, it will be published to `nixpkgs`. It is
currently provided in a flake instead of a pull request to foster quick and rapid
external contributions.

## Usage

The only exposed package of this flake is `oracledb`, there's also a `default`
overlay.

## Status

Not working yet, see Discourse issue @ https://discourse.nixos.org/t/packaging-oracle-database-23c/38697

## Useful links

- https://docs.oracle.com/en/database/oracle/oracle-database/23/xeinl/database-free-installation-guide-linux.pdf
- https://github.com/gvenzl/oci-oracle-free
