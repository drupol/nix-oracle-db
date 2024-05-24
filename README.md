# Oracle Database on Nix

The goal of this project is to provide a Nix flake that can be used to build
and use Oracle Database on Nix.

Once the flake is in a working state, it will be published to `nixpkgs`. It is
currently provided in a flake instead of a pull request to foster quick and rapid
external contributions.

## Usage

The only exposed package of this flake is `oracle-database`, there's also a `default`
overlay and a NixOS module.

## NixOS Module

The following modules are exposed:

- `oracle-database` (not working yet)
- `oracle-database-container` (should work)

To use a module, add this project in your flake `inputs`:

```nix
nix-oracle-db.url = "github:drupol/nix-oracle-db";
```

Then, add of of the exposed module in your `configuration.nix`:

```nix
# The configuration here is an example; it will look slightly different
# based on your platform (NixOS, nix-darwin) and architecture.
nixosConfigurations.your-box = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux"

    modules = [
        # This is the important part -- add this line to your module list!
        inputs.nix-oracle-db.nixosModules.oracle-database-container
    ];
};
```

And finally, enable the service:

```nix

services.oracle-database-container = {
    enable = true;
    openFirewall = true;
};
```

## Test

Use `nix build .#oracle-database-test -L`

## Status

Basic binaries are working! I don't like the current implementation, I hope I
will find a better solution in the upcoming days.

## Useful links

- https://docs.oracle.com/en/database/oracle/oracle-database/23/xeinl/database-free-installation-guide-linux.pdf
- https://github.com/gvenzl/oci-oracle-free
