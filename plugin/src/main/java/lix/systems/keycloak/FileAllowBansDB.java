package lix.systems.keycloak;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * File based allow/ban lists implementation.
 * The file in use has two space separated columns, ID and USERNAME respectively
 */
public class FileAllowBansDB implements AllowBansDB {
    private static final Logger LOG = LoggerFactory.getLogger(FileAllowBansDB.class);
    private final Path basePath;

    public FileAllowBansDB(Path basePath) {
        this.basePath = basePath;
    }

    private Set<String> idsInFile(Path file) throws FileNotFoundException {
        // Kinda yolo, we probably should care more, but our ban list and allow list are never going to be long
        var reader = new BufferedReader(new FileReader(file.toFile()));
        return reader.lines().filter(l -> !l.startsWith("#") && !l.isEmpty()).map(l -> l.split(" ")[0]).collect(Collectors.toUnmodifiableSet());
    }

    @Override
    public boolean isUserExplicitlyAllowedById(String id) {
        var subpath = basePath.resolve("allowed-users.txt");
        try {
            var ids = idsInFile(subpath);
            return ids.contains(id);
        } catch (FileNotFoundException e) {
            LOG.error("Missing file {}", subpath);
            return false;
        }
    }

    @Override
    public boolean isUserBannedById(String id) {
        var subpath = basePath.resolve("banned-users.txt");
        try {
            var ids = idsInFile(subpath);
            return ids.contains(id);
        } catch (FileNotFoundException e) {
            LOG.error("Missing file {}", subpath);
            return false;
        }
    }

    @Override
    public boolean isUsingAllowList() {
        return basePath.resolve("use-allow-list.txt").toFile().exists();
    }
}
