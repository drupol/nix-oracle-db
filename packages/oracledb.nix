{ lib
, stdenv
, fetchurl

, autoPatchelfHook
, makeBinaryWrapper
, rpmextract
, libaio
, alsa-lib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "oracle-database";
  version = "23c";

  src = fetchurl {
    url = "https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23c-1.0-1.el8.x86_64.rpm";
    hash = "sha256-Exm818twbLcnUBy9mKvz85gKT9q+thOhq//HVpJcc3Q=";
  };

  autoPatchelfIgnoreMissingDeps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
    rpmextract
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    libaio
    alsa-lib
  ];

  preBuild = ''
    addAutoPatchelfSearchPath "${placeholder "out"}/opt/oracle/product/23c/dbhomeFree/lib/"
  '';

  unpackCmd = ''
    mkdir ${finalAttrs.pname}-${finalAttrs.version} && pushd ${finalAttrs.pname}-${finalAttrs.version}
    rpmextract $curSrc
    popd
  '';

  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out $out/bin $lib/lib
    cp -ar {etc,opt,usr} $out

    runHook postInstall
  '';

  postInstall = ''
    for exe in "$out/opt/oracle/product/23c/dbhomeFree/bin/"* ; do
      test -x "$exe" && makeWrapper $exe "$out/bin/$(basename "$exe")"
    done
  '';

  outputs = [ "out" "dev" "lib" ];

  meta = {
    description = "Oracle database";
    homepage = "http://www.oracle.com";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ drupol ];
  };
})
