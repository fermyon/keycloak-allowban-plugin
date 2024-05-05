{ maven }:
maven.buildMavenPackage {
  pname = "keycloak-lists-plugin";
  version = "1.0";

  src = ./plugin;

  mvnHash = "sha256-93INDkc0FPEqYaPE8NRq6m/Rfc9AZb4w5ycRTnbXMdQ=";

  buildPhase = ''
    mvn --offline package;
  '';

  installPhase = ''
    mkdir -p $out
    install -Dm644 target/*.jar $out
  '';
}
