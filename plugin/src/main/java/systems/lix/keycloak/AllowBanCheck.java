package systems.lix.keycloak;

import jakarta.ws.rs.core.Response;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.AuthenticationFlowError;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AllowBanCheck implements Authenticator {
    private static final Logger LOG = LoggerFactory.getLogger(AllowBanCheck.class);
    private final AllowBansDB allowBansDB;

    public AllowBanCheck(AllowBansDB allowBansDB) {
        this.allowBansDB = allowBansDB;
    }

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        // Requires mapper that puts it into a githubId field on the user.
        // The reason that we don't use the external ID link is that people can delete those.
        var attr = context.getUser().getFirstAttribute("githubId");

        // The empty case is only if there is a mistake in a user
        if (attr == null || attr.isEmpty()) {
            // We don't think this should be "attempted", because this must be
            // a required authenticator, and we want to pass if we don't apply.
            context.success();
            return;
        }

        if (allowBansDB.isUserBannedById(attr)) {
            LOG.error("User {} is banned", context.getUser().getUsername());
            context.getEvent().error("User is banned");
            var challenge = context.form().setError("User is banned!").createErrorPage(Response.Status.UNAUTHORIZED);
            context.failure(AuthenticationFlowError.ACCESS_DENIED, challenge);
            return;
        } else if (allowBansDB.isUsingAllowList() && !allowBansDB.isUserExplicitlyAllowedById(attr)) {
            LOG.error("User {} is not allow-listed", context.getUser().getUsername());
            context.getEvent().error("User is not allow-listed");
            var challenge = context.form().setError("User is not allow-listed!").createErrorPage(Response.Status.UNAUTHORIZED);
            context.failure(AuthenticationFlowError.ACCESS_DENIED, challenge);
            return;
        }

        context.success();
    }

    @Override
    public void action(AuthenticationFlowContext authenticationFlowContext) {

    }

    @Override
    public boolean requiresUser() {
        return true;
    }

    @Override
    public boolean configuredFor(KeycloakSession keycloakSession, RealmModel realmModel, UserModel userModel) {
        // "Credential setup required" error if false is returned here.
        return true;
    }

    @Override
    public void setRequiredActions(KeycloakSession keycloakSession, RealmModel realmModel, UserModel userModel) {

    }

    @Override
    public void close() {

    }
}
