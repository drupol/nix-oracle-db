{ lib
, stdenvNoCC
, fetchurl
, buildFHSEnv
, writeScript
, rpmextract
, libaio
, alsa-lib
, runtimeShell
}:
let
  oracle-database-base = stdenvNoCC.mkDerivation (finalAttrs: {
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

  extraInstallCommands = ''
    WRAPPER=$out/bin/oracle-database

    mkdir -p $out/bin
    find ${oracle-database-base.bin}/bin -type f -executable -print0 | while read -d $'\0' executable
    do
      exe=$(cut -d"/" -f5- <<< $executable)
      echo "#!${runtimeShell}" >> $out/$exe
      echo "$WRAPPER ${oracle-database-base.bin}/$exe \"\$@\"" >> $out/bin/$(basename $exe)
      chmod +x $out/$exe
    done

    mkdir -p $out/etc/init.d
    echo "#!${runtimeShell}" >> $out/etc/init.d/oracle-free-23c
    echo "$WRAPPER ${oracle-database-base}/etc/init.d/oracle-free-23c \"\$@\"" >> $out/etc/init.d/oracle-free-23c
    chmod +x $out/etc/init.d/oracle-free-23c
  '';
}
