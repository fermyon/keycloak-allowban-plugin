package systems.lix.keycloak;

/**
 * A database of whether users are allow-listed or banned.
 */
public interface AllowBansDB {
    /**
     * Gets if a user is in the allow list by ID.
     */
    boolean isUserExplicitlyAllowedById(String id);

    /**
     * Gets if a user is in the ban list by ID.
     */
    boolean isUserBannedById(String id);

    /**
     * Whether to only allow users on allow-list to get in.
     */
    boolean isUsingAllowList();
}
