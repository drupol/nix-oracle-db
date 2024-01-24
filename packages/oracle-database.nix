{ lib
, stdenvNoCC
, fetchurl
, buildFHSEnv
, writeScript
, rpmextract
, libaio
, alsa-lib
, makeBinaryWrapper
}:
let
  oracle-database-unwrapped = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "oracle-database-unwrapped";
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

      mkdir -p $out $bin $lib $etc
      cp -ar opt/oracle/product/${finalAttrs.version}/dbhomeFree/* $out
      cp -ar etc $etc/
      mv $out/lib $lib/
      mv $out/bin $bin/

      # to be confirmed: Remove these files as they are not needed.
      rm -rf $lib/lib/pkgconfig
      rm -rf $lib/lib/cmake

      runHook postInstall
    '';

    outputs = [ "out" "bin" "lib" "etc" ];
  });

  fhs = buildFHSEnv {
    name = "oracle-database";

    targetPkgs = pkgs: [
      oracle-database-unwrapped
      libaio
      alsa-lib
    ];

    runScript = writeScript "oracle-database-fhs-wrapper" ''
      exec "$@"
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "oracle-database";
  inherit (oracle-database-unwrapped) version;

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  installPhase = ''
    runHook preInstall

    WRAPPER=${fhs}/bin/${fhs.name}

    mkdir -p $out

    find ${oracle-database-unwrapped.bin}/bin -type f -executable -print0 | while read -d $'\0' executable
    do
      exe=$(cut -d"/" -f5- <<< $executable)
      makeWrapper $WRAPPER $out/bin/$(basename $exe) \
        --set-default ORACLE_HOME ${oracle-database-unwrapped} \
        --add-flags $executable
    done

    find ${oracle-database-unwrapped.etc}/etc/init.d -type f -executable -print0 | while read -d $'\0' executable
    do
      exe=$(cut -d"/" -f5- <<< $executable)
      makeWrapper $WRAPPER $out/$exe \
          --set-default ORACLE_HOME ${oracle-database-unwrapped} \
          --add-flags $executable
    done

    runHook postInstall
  '';

  meta = {
    description = "Oracle Database";
    homepage = "http://www.oracle.com";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ drupol ];
  };
}
