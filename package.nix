{ maven }:
maven.buildMavenPackage {
  pname = "keycloak-lists-plugin";
  version = "1.0";

  src = ./plugin;

  mvnHash = "sha256-UaVCt6KIjR8i3vHVp5YWqu8zzM7mftXyrv5J2jxtw6Q=";

  buildPhase = ''
    mvn --offline package;
  '';

  installPhase = ''
    mkdir -p $out
    install -Dm644 target/*.jar $out
  '';
}
