{ __nixpkgs__
, attrsMapToList
, inputs
, makeTemplate
, makeScript
, toBashMap
, ...
}:
let
  toFileJson = name: data: builtins.toFile name (builtins.toJSON data);

  toSemverList = attrs:
    builtins.sort
      (a: b:
        if a.name == "latest" || a.name == "pythonLatest"
        then true
        else if b.name == "latest" || b.name == "pythonLatest"
        then false
        else (builtins.compareVersions a.name b.name) > 0)
      (attrsMapToList (name: data: { inherit data name; }) attrs);

  projects = builtins.mapAttrs
    (project: projectMeta: {
      title = project;
      meta = projectMeta.meta;
      setup =
        if builtins.pathExists projectMeta.setupPath
        then builtins.readFile projectMeta.setupPath
        else null;
      tests = builtins.readFile projectMeta.testPath;
      versions = toSemverList
        (builtins.mapAttrs
          (version: versionMeta: {
            pythonVersions = toSemverList
              (builtins.removeAttrs
                (builtins.mapAttrs
                  (pythonVersion: pythonVersionMeta: {
                    demos = {
                      tryItOut = {
                        stable = ''
                          $ nix-shell \
                            --attr 'projects."${project}"."${version}".${pythonVersion}.dev' \
                            'https://github.com/on-nix/python/tarball/${inputs.pythonOnNixRev}'
                        '';
                        flakes = ''
                          $ nix develop \
                            'github:on-nix/python/${inputs.pythonOnNixRev}#"${project}-${version}-${pythonVersion}"'
                        '';
                      };
                    };
                    nameShort = {
                      "python36" = "36";
                      "python37" = "37";
                      "python38" = "38";
                      "python39" = "39";
                      "python310" = "310";
                    }.${pythonVersion};
                    inherit (pythonVersionMeta) closure;
                  })
                  (versionMeta.pythonVersions))
                [ "pythonLatest" ]
              );
          })
          (projectMeta.versions));
    })
    (if inputs.prod
    then inputs.pythonOnNix.projectsMeta
    else {
      about-time = inputs.pythonOnNix.projectsMeta.about-time;
      botocore = inputs.pythonOnNix.projectsMeta.botocore;
      django = inputs.pythonOnNix.projectsMeta.django;
    });
in
makeScript {
  name = "generate-data";
  entrypoint = ./entrypoint.sh;
  replace = {
    __argData__ = __nixpkgs__.linkFarm "data"
      (builtins.foldl'
        (all: project: builtins.foldl'
          (all: version: builtins.foldl'
            (all: pythonVersion: all ++ [{
              name = "projects/by_tree/${project}/${version.name}/${pythonVersion.name}";
              path = toFileJson
                "${project}-${version.name}-${pythonVersion.name}"
                (projects.${project} // {
                  inherit version;
                  inherit pythonVersion;
                });
            }])
            (all)
            (version.data.pythonVersions))
          (all ++ [{
            name = "projects/by_name/${project}";
            path = toFileJson project projects.${project};
          }])
          (projects.${project}.versions))
        [ ]
        (builtins.attrNames projects));
  };
}
