{ lib
, stdenv
, fetchurl
, buildFHSEnv
, writeScript
, rpmextract
, libaio
, alsa-lib
, runtimeShell
}:
let
  oracle-database-base = stdenv.mkDerivation (finalAttrs: {
    pname = "oracle-database-base";
    version = "23c";

    src = fetchurl {
      url = "https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23c-1.0-1.el8.x86_64.rpm";
      hash = "sha256-Exm818twbLcnUBy9mKvz85gKT9q+thOhq//HVpJcc3Q=";
    };

    nativeBuildInputs = [
      rpmextract
    ];

    unpackCmd = ''
      mkdir ${finalAttrs.pname}-${finalAttrs.version} && pushd ${finalAttrs.pname}-${finalAttrs.version}
      rpmextract $curSrc
      popd
    '';

    dontPatchShebangs = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out $out/bin $lib/lib $bin/bin
      cp -ar {etc,opt,usr} $out
      cp -ar opt/oracle/product/23c/dbhomeFree/lib/* $lib/lib/
      cp -ar opt/oracle/product/23c/dbhomeFree/bin/* $bin/bin/

      runHook postInstall
    '';

    outputs = [ "out" "bin" "dev" "lib" ];
  });
in
buildFHSEnv {
  name = "oracle-database";

  targetPkgs = pkgs: [
    oracle-database-base
    libaio
    alsa-lib
  ];

  runScript = writeScript "oracle-database-wrapper" ''
    export ORACLE_HOME=${oracle-database-base.out}/opt/oracle/product/23c/dbhomeFree
    exec "$@"
  '';

  extraInstallCommands =
    let
      executables = [
        "bin/acfsroot"
        "bin/adapters"
        "bin/adrci"
        "bin/afddriverstate"
        "bin/afdroot"
        "bin/afdtool"
        "bin/afdtool.bin"
        "bin/agtctl"
        "bin/ahfctl"
        "bin/amdu"
        "bin/aqxmlctl"
        "bin/asmcmd"
        "bin/asmcmdcore"
        "bin/bdschecksw"
        "bin/chopt"
        "bin/chopt.ini"
        "bin/chopt.pl"
        "bin/cluvfy"
        "bin/cluvfyrac.sh"
        "bin/CommonSetup.pm"
        "bin/commonSetup.sh"
        "bin/connstr"
        "bin/coraenv"
        "bin/ctxkbtc"
        "bin/ctxlc"
        "bin/ctxload"
        "bin/cursize"
        "bin/dbca"
        "bin/dbdowngrade"
        "bin/dbfs_client"
        "bin/dbfsize"
        "bin/dbgeu_run_action.pl"
        "bin/dbhome"
        "bin/dbnest"
        "bin/dbnestinit"
        "bin/dbreload"
        "bin/dbSetup.pl"
        "bin/dbshut"
        "bin/dbstart"
        "bin/dbua"
        "bin/dbupgrade"
        "bin/dbv"
        "bin/deploync"
        "bin/dg4odbc"
        "bin/dg4pwd"
        "bin/dgmgrl"
        "bin/diagsetup"
        "bin/diskmon"
        "bin/dropjava"
        "bin/dsml2ldif"
        "bin/dumpsga"
        "bin/echodo"
        "bin/emca"
        "bin/emdwgrd"
        "bin/emdwgrd.pl"
        "bin/enable_fips.py"
        "bin/eusm"
        "bin/exp"
        "bin/expdp"
        "bin/extjob"
        "bin/extjobo"
        "bin/extproc"
        "bin/extusrupgrade"
        "bin/fmputl"
        "bin/fmputlhp"
        "bin/gwsadv"
        "bin/hsalloci"
        "bin/hsdepxa"
        "bin/hsots"
        "bin/imp"
        "bin/impdp"
        "bin/invctl"
        "bin/jssu"
        "bin/kfed"
        "bin/kfod"
        "bin/kfod.bin"
        "bin/kgmgr"
        "bin/lcsscan"
        "bin/ldapadd"
        "bin/ldapaddmt"
        "bin/ldapbind"
        "bin/ldapcompare"
        "bin/ldapdelete"
        "bin/ldapmoddn"
        "bin/ldapmodify"
        "bin/ldapmodifymt"
        "bin/ldapsearch"
        "bin/ldifmigrator"
        "bin/linkshlib"
        "bin/lmsgen"
        "bin/loadjava"
        "bin/loadpsp"
        "bin/lsnrctl"
        "bin/lxchknlb"
        "bin/lxegen"
        "bin/lxinst"
        "bin/mapsga"
        "bin/maxmem"
        "bin/mkpatch"
        "bin/mkstore"
        "bin/mtactl"
        "bin/ncomp"
        "bin/netca"
        "bin/netca_deinst.sh"
        "bin/netmgr"
        "bin/nid"
        "bin/odisrvreg"
        "bin/oerr"
        "bin/oerr.pl"
        "bin/oidca"
        "bin/oidprovtool"
        "bin/ojvmjava"
        "bin/ojvmtc"
        "bin/okbcfg"
        "bin/okcreate"
        "bin/okdstry"
        "bin/okdstry0"
        "bin/okinit"
        "bin/okinit0"
        "bin/oklist"
        "bin/oklist0"
        "bin/olsadmintool"
        "bin/olsoidsync"
        "bin/oms_daemon"
        "bin/omsfscmds"
        "bin/onsctl"
        "bin/oputil"
        "bin/ora_server_kill"
        "bin/orabase"
        "bin/orabaseconfig"
        "bin/orabasehome"
        "bin/oracg"
        "bin/orachk"
        "bin/oracle"
        "bin/oradism"
        "bin/oradnfs"
        "bin/oradnfs_run.sh"
        "bin/oraenv"
        "bin/orajaxb"
        "bin/orald"
        "bin/oraping"
        "bin/orapipe"
        "bin/orapki"
        "bin/orapwd"
        "bin/oraversion"
        "bin/oraxml"
        "bin/oraxsl"
        "bin/ORE"
        "bin/ore_destimport.pl"
        "bin/ore_dsiexport.pl"
        "bin/ore_dsiimport.pl"
        "bin/ore_srcexport.pl"
        "bin/orion"
        "bin/osdbagrp"
        "bin/osegtab"
        "bin/osh"
        "bin/ott"
        "bin/patchgen"
        "bin/platform_common"
        "bin/plshprof"
        "bin/proc"
        "bin/procob"
        "bin/rconfig"
        "bin/relink"
        "bin/renamedg"
        "bin/rhpctl"
        "bin/rman"
        "bin/roohctl"
        "bin/rootPreRequired.sh"
        "bin/rrpatch"
        "bin/rrpatch.pl"
        "bin/rrpatch.py"
        "bin/rrputil"
        "bin/rtsora"
        "bin/sbttest"
        "bin/schagent"
        "bin/schema"
        "bin/schemasync"
        "bin/skgxpinfo"
        "bin/sqlldr"
        "bin/sqlplus"
        "bin/srvctl"
        "bin/statusnc"
        "bin/symfind"
        "bin/sysresv"
        "bin/tfactl"
        "bin/tkprof"
        "bin/tnnfg"
        "bin/tnslsnr"
        "bin/tnsping"
        "bin/transx"
        "bin/trcasst"
        "bin/trcroute"
        "bin/trcsess"
        "bin/tstshm"
        "bin/uidrvci"
        "bin/wrap"
        "bin/wrc"
        "bin/xml"
        "bin/xmlcg"
        "bin/xmldiff"
        "bin/xmlpatch"
        "bin/xmlwf"
        "bin/xsl"
        "bin/xsql"
        "bin/xvm"
      ];
    in
    ''
      WRAPPER=$out/bin/oracle-database
      EXECUTABLES="${lib.concatStringsSep " " executables}"
      for executable in $EXECUTABLES; do
        mkdir -p $out/$(dirname $executable)

        echo "#!${runtimeShell}" >> $out/$executable
        echo "$WRAPPER ${oracle-database-base.bin}/$executable \"\$@\"" >> $out/$executable
      done

      cd $out
      chmod +x $EXECUTABLES
    '';
}
