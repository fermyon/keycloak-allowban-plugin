{ pkgs, lib, ... }:
let
  # Server we're hosting on.
  host = "identity.test.lix.systems";

  # Realm used for services.
  realm = "lix-project";

in
{
  users.users.root.password = "";
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  services.keycloak = {
    enable = true;

    settings = {
      hostname = host;

      # Always talk through our reverse proxy.
      http-port = 9091;
      proxy = "edge";
    };

    # This will be immediately changed, so no harm in having it here.
    initialAdminPassword = "Password1";

    # Automatically manage our database.
    database = {
      createLocally = true;
      # DO NOT DO THIS IN PROD
      passwordFile = builtins.toFile "bad-db-password" "Password1";
    };

    settings = {
      log-level = "INFO";
      spi-authenticator-allow-ban-check-authenticator-dbpath = "/var/keycloak-allow-bans";
    };
  };

  # Postgres server for the storage backend.
  services.postgresql.enable = true;

  # Create a static user, so we can set up our keys beforehand.
  # This overrides the dynamic user creation in the base module config.
  users.users.keycloak = {
    isSystemUser = true;
    group = "keycloak";
  };
  users.groups.keycloak = { };

  # Reverse proxy our data over https.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;

    virtualHosts = {
      "${host}" = {
        forceSSL = true;
        sslCertificate = "/var/lib/nginx/nc-selfsigned.crt";
        sslCertificateKey = "/var/lib/nginx/nc-selfsigned.key";

        locations."/" = {
          proxyPass = "http://127.0.0.1:9091";
          extraConfig = ''
            proxy_ssl_server_name on;
            proxy_pass_header Authorization;
            proxy_set_header X-Forwarded-For $proxy_protocol_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;

            proxy_busy_buffers_size   512k;
            proxy_buffers   4 512k;
            proxy_buffer_size   256k;

            # Allow clients with Auth hardcoded to use our base path.
            #
            # XXX: ok so this is horrible. For some reason gerrit explodes if
            # it receives a redirect when doing auth. But we need to redirect
            # the browser to reuse sessions. Thus, user agent scanning.
            if ($http_user_agent ~* "^Java.*$") {
              rewrite ^/auth/(.*)$ /$1 last;
            }
            rewrite ^/auth/(.*)$ /$1 redirect;

            # Hacks to make us compatible with authenticators that expect GitLab's format.
            rewrite ^/realms/${realm}/protocol/openid-connect/api/v4/user$ /realms/${realm}/protocol/openid-connect/userinfo;
            rewrite ^/realms/${realm}/protocol/openid-connect/oauth/authorize$ /realms/${realm}/protocol/openid-connect/auth?scope=openid%20email%20profile;
            rewrite ^/realms/${realm}/protocol/openid-connect/oauth/token$ /realms/${realm}/protocol/openid-connect/token;
          '';
        };

        # Forward our admin address to our default realm.
        locations."= /admin".extraConfig = "return 302 https://${host}/admin/lix-project/console/;";
        locations."= /superadmin".extraConfig = "return 302 https://${host}/admin/master/console/;";

        # Forward our root address to the account management portal.
        locations."= /".extraConfig = "return 302 https://${host}/realms/${realm}/account;";
      };
    };
  };

  systemd.services.cert-setup = {
    wantedBy = [ "nginx.service" ];
    before = [ "nginx.service" ];
    serviceConfig = {
      ConditionFileExists = "!/var/lib/nginx/nc-selfsigned.crt";
      ExecStart = [
        "${lib.getBin pkgs.openssl}/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj /CN=identity.test.lix.systems/ -keyout /var/lib/nginx/nc-selfsigned.key -out /var/lib/nginx/nc-selfsigned.crt"
        "${lib.getBin pkgs.coreutils}/bin/chown nginx:nginx /var/lib/nginx/nc-selfsigned.key /var/lib/nginx/nc-selfsigned.crt"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/nginx 755 nginx nginx -"
  ];

  microvm = {
    hypervisor = "qemu";
    mem = 1024;
    interfaces = [{
      type = "user";
      id = "microvm";
      mac = "02:00:00:00:00:01";
    }];

    forwardPorts = [
      {
        from = "host";
        guest.port = 443;
        host.port = 4043;
        proto = "tcp";
      }
      {
        from = "host";
        guest.port = 22;
        host.port = 2022;
        proto = "tcp";
      }
    ];

    volumes = [{
      mountPoint = "/var";
      image = "var.img";
      size = 256;
    }];
    shares = [{
      proto = "9p";
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }];
  };
}
