{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.services.oracle-database-container;
in
{
  options = {
    services.oracle-database-container = {
      enable = lib.mkEnableOption "the Oracle Database server";

      port = mkOption {
        default = 1521;
        description = "The TCP port Audiobookshelf will listen on.";
        type = types.port;
      };

      version = mkOption {
        default = "23.4.0.0";
        description = "The version of the Oracle Database server to use.";
        type = types.str;
      };

      openFirewall = mkOption {
        default = false;
        description = "Open ports in the firewall";
        type = types.bool;
      };

      dataDir = mkOption {
        default = "/var/lib/oracledb";
        description = "The directory where the Oracle Database will store its data.";
        type = types.path;
      };

      password = lib.mkOption {
        default = "oracle";
        description = "The Oracle Database SYS, SYSTEM and PDB_ADMIN password";
        type = lib.types.str;
      };

      charset = mkOption {
        default = "AL32UTF8";
        description = "The character set to use when creating the database";
        type = types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = {
      "oracle-database-container" = {
        preStart = ''
          mkdir -p ${cfg.dataDir}
          echo "${cfg.password}" | ${lib.getExe pkgs.podman} secret create oracle_pwd -
        '';
        wantedBy = [ "podman-oracledb.service" ];
        before = [ "podman-oracledb.service" ];
      };
    };

    virtualisation = {
      oci-containers.containers = {
        oracledb = {
          image = "container-registry.oracle.com/database/free:${cfg.version}";
          environment = {
            ORACLE_CHARACTERSET = cfg.charset;
            # schema of the dump you want to import
            # SOURCE_SCHEMA = "change-or-delete-me";
            # tablespace of the dump you want to import
            # SOURCE_TABLESPACE = "change-or-delete-me";
            # you may want to exclude `GRANT`: `EXCLUDE=USER,GRANT', if your dump contains them
            # if you dont have anything to exclude, remove the variable
            # EXCLUDE = "user";
          };
          ports = [ "${toString cfg.port}:1521" ];
          volumes = [ "${cfg.dataDir}:/opt/oracle/oradata" ];
          extraOptions = [ "--secret=oracle_pwd" ];
        };
      };
    };

    networking.firewall = mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
