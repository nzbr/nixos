{ lib, ... }:
with builtins; with lib; {
  # Given a filename suffix and a path to a directory,
  # recursively finds all files whose names end in that suffix.
  # Returns the filenames as a list
  findModules =
    suffix: dir:
    flatten (
      mapAttrsToList
        (
          name: type:
          if type == "directory" then
            findModules suffix (dir + "/${name}")
          else
            let
              fileName = dir + "/${name}";
            in
            if hasSuffix suffix fileName
            then fileName
            else [ ]
        )
        (readDir dir)
    );

  nameValuePair' =
    name: value:
    # String carries context of the derivation the file comes from.
    # It is only used as the name of an attribute here.
    # It should be safe to discard it. (I hope)
    nameValuePair (unsafeDiscardStringContext name) value;

  # Given an instance of nixpkgs, a filename suffix and a path to a directory,
  # uses findModules to recursively find files with names that end in the specified suffix and
  # loads those files as packages using callPackage from the specified nixpkgs instance.
  # Returns a list of derivations
  loadPackages =
    channel: specialArgs: suffix: dir:
    listToAttrs (
      map
        (
          pkg:
          nameValuePair'
            (removeSuffix suffix (baseNameOf pkg))
            (channel.callPackage (import pkg) specialArgs)
        )
        (
          findModules suffix dir
        )
    );

  # Given a file path, returns the file contents removing a trailing newline if it is present
  readFile' = path: removeSuffix "\n" (readFile path);

}
