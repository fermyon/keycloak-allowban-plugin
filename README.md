# Keycloak allow/ban plugin

This is a plugin for Keycloak that checks an allow-list and a ban list for
users from GitHub.

## Configuration

Add the plugin to your keycloak plugins list. The plugin can be obtained via
`nix build .#packages.default`.

The configuration of this plugin is in a directory of text files with the
format `github-id github-username`, allowing `#` comments.

Specify a Keycloak config file option
`spi-authenticator-allow-ban-check-authenticator-dbpath` pointing to the
directory with the configuration. Note that the error if you don't configure
this is complete garbage, and is also not printed by default (sorry)! Use
`kc.sh --verbose start` to read your `NullPointerException`.

There are three notable files in there:
- `banned-users.txt`: contains a list of GitHub IDs which will be rejected
  outright on login.

  If you newly ban a user, you have to kill all their sessions across all
  infrastructure, including existing Keycloak sessions, since bans only apply
  on login.
- `allowed-users.txt`: contains a list of GitHub IDs which will be allowed if the
  allow-list is enabled.
- `use-allow-list.txt`: if present, the allow-list mechanism is used. Otherwise
  it is bypassed and all logins are allowed.

The intent of the configuration is that it is synced by a cron job pulling a
git repo.

## Setup

1. In the GitHub Identity Provider configuration on Keycloak, set up a mapper with
   type "Attribute Importer", importing the JSON field path "id" as a user
   profile attribute "githubId".

2. Create an auth flow for post login on the identity provider, containing one
   element "Allow/Ban check". This is necessary since it bypasses the standard
   login flow if you log in via the external IdP.

3. In the identity provider, set the *Post Login Flow* to the flow just
   created.

4. Add the "Allow/Ban check" action to the main login flow as a Required
   element at a point *after* the username is determined.

## Notes

We are unsure if Store Tokens is necessary to set; it is not for this plugin,
but it might be a good idea to simply have them around.

We don't think there are ways to ban-evade, since this is managed by a
user-invisible profile attribute that is permanently glued to all accounts
originating from GitHub.

We have tested this on Keycloak 23 and 24.

### Test environment!

There is a test environment included with this plugin to avoid testing in prod.
Run:

```
nix run .#
```

Then in a separate terminal:

```
sudo socat TCP-LISTEN:443,fork,reuseaddr TCP:127.0.0.1:4043
```

and add `127.0.0.1 identity.test.lix.systems` to `/etc/hosts`. Dump Firefox
DNS cache if necessary (`about:networking`), and create a GitHub OAuth app.

You can ssh into the machine on port 2022 on localhost as root, with no
password.

Then finally go to `https://identity.test.lix.systems/superadmin`, and log in
with `admin`/`Password1`.

### Attaching a debugger to Keycloak

We are so sorry.

If you are doing this to the VM here, change the last line of the keycloak
startup script to this:

`DEBUG=true DEBUG_PORT='*:1337' DEBUG_SUSPEND=y kc.sh --verbose start --optimized --debug`

To actually make that work, you want to copy the file from `systemctl cat
keycloak.service` to `/start-keycloak`, then `systemctl edit --runtime
keycloak`, with the contents:

```
[Service]
ExecStart=
ExecStart=/start-keycloak
```

Then `systemctl restart keycloak`. Next create a forward like `ssh
-L1337:localhost:1337 localvm` and attach your Java debugger to port 1337.
