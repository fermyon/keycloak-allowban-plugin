package systems.lix.keycloak;

import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

import java.nio.file.Path;
import java.util.List;

/** buddy i just work in the allow ban check factory */
public class AllowBanCheckFactory implements AuthenticatorFactory {
    private Path dbPath = null;
    public static final String PROVIDER_ID = "allow-ban-check-authenticator";

    @Override
    public String getDisplayType() {
        return "Allow/ban check";
    }

    @Override
    public String getReferenceCategory() {
        return null;
    }

    @Override
    public boolean isConfigurable() {
        return false;
    }

    @Override
    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return REQUIREMENTS_CHOICES;
    }

    private static final AuthenticationExecutionModel.Requirement[] REQUIREMENTS_CHOICES = {
            AuthenticationExecutionModel.Requirement.REQUIRED,
            AuthenticationExecutionModel.Requirement.DISABLED,
    };

    @Override
    public boolean isUserSetupAllowed() {
        return false;
    }

    @Override
    public String getHelpText() {
        return "Meow meow meow meow meow";
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return List.of();
    }

    @Override
    public Authenticator create(KeycloakSession keycloakSession) {
        return new AllowBanCheck(new FileAllowBansDB(dbPath));
    }

    @Override
    public void init(Config.Scope scope) {
        dbPath = Path.of(scope.get("dbpath"));
    }

    @Override
    public void postInit(KeycloakSessionFactory keycloakSessionFactory) {

    }

    @Override
    public void close() {

    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
