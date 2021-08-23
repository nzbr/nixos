{ lib, pkgs, ... }:
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
    # It is only used to find the derivation that should carry that information anyway.
    # It should be safe to discard it. (I hope)
    nameValuePair (unsafeDiscardStringContext name) value;

  # Given an instance of nixpkgs, a filename suffix and a path to a directory,
  # uses findModules to recursivelz find files with names that end in the specified suffix and
  # loads those files as packages using callPackage from the specified nixpkgs instance.
  # Returns a list of derivations
  loadPackages =
    channel: suffix: dir:
    listToAttrs (
      map
        (
          pkg:
          nameValuePair'
            (removeSuffix suffix (baseNameOf pkg))
            (channel.callPackage (import pkg) { })
        )
        (
          findModules suffix dir
        )
    );

}
