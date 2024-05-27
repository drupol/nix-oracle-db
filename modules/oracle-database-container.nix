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

      volumeName = mkOption {
        default = "oracledb";
        description = ''
          The volume where the Oracle Database will store its data.
          Set an existing directory to persist the data between container
          restarts, but be aware that Oracle requires a specific directory
          structure with specific files. If you want to persist the data,
          the best option is to use a Docker volume at the moment. Leave empty
          to use a stateless container.

          More info on this at:
            - https://github.com/oracle/docker-images/issues/1533
            - https://github.com/oracle/docker-images/issues/640
            - https://github.com/OxalisCommunity/oxalis/issues/440
        '';
        type = types.nullOr types.str;
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        description = "Path to file containing the Oracle Database SYS, SYSTEM and PDB_ADMIN password.";
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
          ${lib.getExe pkgs.podman} secret rm --ignore oracle_pwd
        '';
        wantedBy = [ "podman-oracledb.service" ];
        before = [ "podman-oracledb.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ''
            ${lib.getExe pkgs.podman} secret create oracle_pwd %d/oracle_pwd
          '';
          LoadCredential = [ "oracle_pwd:${cfg.passwordFile}" ];
        };
      };
    };

    virtualisation = {
      podman.defaultNetwork.settings.dns_enabled = true;

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
          volumes = [ ] ++ lib.optionals (null != cfg.volumeName) [ "${cfg.volumeName}:/opt/oracle/oradata" ];
          extraOptions = [ "--secret=oracle_pwd" ];
        };
      };
    };

    networking.firewall = mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
