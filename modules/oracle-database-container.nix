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

      ociEngine = mkOption {
        default = "podman";
        description = "The container engine to use.";
        type = types.enum [
          "podman"
          "docker"
        ];
      };

      version = mkOption {
        default = "23.4.0.0";
        description = "The version of the Oracle Database server to use.";
        type = types.str;
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

      copyInitialFilesToDirectory = mkOption {
        default = true;
        description = ''
          Copy the initial files to the volume.
          This is necessary to create the database.
          If you are using a volume which is a directory and not a Volume, you
          should set this to true.
        '';
        type = types.bool;
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

      openFirewall = mkOption {
        default = false;
        description = "Open ports in the firewall";
        type = types.bool;
      };
    };
  };

  config =
    let
      image = "container-registry.oracle.com/database/free:${cfg.version}";
      ociEnginePkg = pkgs."${cfg.ociEngine}";
    in
    lib.mkIf cfg.enable {
      systemd.services =
        lib.optionalAttrs (cfg.passwordFile != null) {
          "${cfg.ociEngine}-database-secret-setup" = {
            wantedBy = [ "${cfg.ociEngine}-oracledb.service" ];
            before = [ "${cfg.ociEngine}-oracledb.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = false;
              ExecStart = pkgs.writeShellScript "oracle-database-secret-setup" ''
                ${lib.getExe ociEnginePkg} secret rm --ignore oracle_pwd
                ${lib.getExe ociEnginePkg} secret create oracle_pwd %d/oracle_pwd
              '';
              LoadCredential = [ "oracle_pwd:${cfg.passwordFile}" ];
            };
          };
        }
        // lib.optionalAttrs cfg.copyInitialFilesToDirectory {
          "${cfg.ociEngine}-database-volume-setup" = {
            wantedBy = [ "${cfg.ociEngine}-oracledb.service" ];
            before = [ "${cfg.ociEngine}-oracledb.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = false;
              ExecStart = pkgs.writeShellScript "oracle-database-container-volume-setup" ''
                mkdir -p ${cfg.volumeName}/oradata
                chmod -R 777 ${cfg.volumeName}
                ${lib.getExe ociEnginePkg} rm --force --ignore oracledbtmp
                ${lib.getExe ociEnginePkg} create --name oracledbtmp ${image}
                ${lib.getExe ociEnginePkg} cp oracledbtmp:/opt/oracle/oradata/ ${cfg.volumeName}/
                ${lib.getExe ociEnginePkg} rm --force --ignore oracledbtmp
              '';
            };
          };
        };

      virtualisation = {
        podman.defaultNetwork.settings.dns_enabled = true;

        oci-containers.containers = {
          oracledb = {
            inherit image;
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
