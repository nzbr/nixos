let
  flake = (import ./default.nix);
  system = builtins.currentSystem;
  lib = flake.lib.${system};

  # The SSH private (user) keys on these hosts will be able to decrypt all secrets
  globalKeyHosts = [ "hurricane" "meteor" "landslide" ];
in
with builtins; with lib;
(
  let
    globalKeys = map (host: readFile' (./machine + "/${host}/ssh/id_ed25519.pub")) globalKeyHosts;

    hostKeys = (
      mapAttrs'
        (name: type:
          nameValuePair
            name
            (
              mapAttrsToList
                (name': type': readFile' (./host-keys + "/${name}/${name'}"))
                (
                  filterAttrs
                    (name': type': (hasSuffix ".pub" name'))
                    (readDir (./host-keys + "/${name}"))
                )
            )
        )
        (
          filterAttrs
            (name: type: type == "directory")
            (readDir ./host-keys)
        )
    );

    allHostKeys = foldl trivial.concat [ ] (mapAttrsToList (host: keys: keys) hostKeys);

    find = dir: map (path: removePrefix "${toString ./.}/" (toString path)) (findModules "" dir);
    genAgeConfig =
      keys: dir:
      listToAttrs (
        map
          (file:
          nameValuePair
            (if hasSuffix ".age" file then file else "${file}.age")
            { publicKeys = keys; }
          )
          (find dir)
      );
  in
  foldl recursiveUpdate { } (
    [
      (genAgeConfig (globalKeys ++ allHostKeys) ./assets)
    ]
    ++
    (
      mapAttrsToList
        (name: keys:
          genAgeConfig (globalKeys ++ keys) (./machine + "/${name}")
        )
        hostKeys
    )
  )
)