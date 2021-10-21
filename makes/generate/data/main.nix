{ __nixpkgs__
, attrsMapToList
, inputs
, makeTemplate
, makeScript
, toBashMap
, toFileJson
, ...
}:
let
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
    (project: projectMeta: toFileJson project {
      title = project;
      meta = projectMeta.meta;
      setup =
        if builtins.pathExists projectMeta.setupPath
        then builtins.readFile projectMeta.setupPath
        else "{ }";
      tests = builtins.readFile projectMeta.testPath;
      versions = toSemverList (builtins.mapAttrs
        (version: versionMeta: {
          pythonVersions = toSemverList (
            builtins.removeAttrs
              (builtins.mapAttrs
                (pythonVersion: pythonVersionMeta: {
                  demo = {
                    nixStable = ''
                      let
                        # import the project
                        nixpkgs = import <nixpkgs> { };
                        pythonOnNix = import
                          (builtins.fetchGit {
                            ref = "${inputs.pythonOnNixRef}";
                            rev = "${inputs.pythonOnNixRev}";
                            url = "${inputs.pythonOnNixUrl}";
                          })
                          {
                            # You can override `nixpkgs` here,
                            # or omit it to use the one bundled with Python on Nix
                            inherit nixpkgs;
                          };

                        # Create a Python on Nix environment
                        env = pythonOnNix.${pythonVersion}Env {
                          name = "example";
                          projects = {
                            "${project}" = "${version}";
                          };
                        };
                      in
                      nixpkgs.stdenv.mkDerivation {
                        buildInputs = [ env ];
                        builder = builtins.toFile "builder.sh" '''
                          source $stdenv/setup

                          # ${project} is now available here!

                          touch $out
                        ''';
                        name = "example";
                      }
                    '';
                    nixUnstable = ''
                      {
                        inputs = {
                          flakeUtils.url = "github:numtide/flake-utils";
                          nixpkgs.url = "github:nixos/nixpkgs";
                          pythonOnNix.url = "github:on-nix/python/${inputs.pythonOnNixRev}";
                        };
                        outputs = { self, ... } @ inputs:
                          inputs.flakeUtils.lib.eachSystem [ "x86_64-linux" ] (system:
                            let
                              nixpkgs = inputs.nixpkgs.legacyPackages.''${system};
                              pythonOnNix = inputs.pythonOnNix.lib {
                                # You can also omit this parameter
                                # in order to use a default `nixpkgs` bundled with Python on Nix
                                inherit nixpkgs;
                                inherit system;
                              };
                            in
                            {
                              packages = rec {

                                example = (pythonOnNix.${pythonVersion}Env {
                                  name = "example";
                                  projects = {
                                    "${project}" = "${version}";
                                  };
                                }).dev;

                                something = nixpkgs.stdenv.mkDerivation {
                                  buildInputs = [ example ];
                                  builder = builtins.toFile "builder.sh" '''
                                    source $stdenv/setup

                                    # ${project} is now available here!

                                    touch $out
                                  ''';
                                  name = "something";
                                };

                              };
                            }
                          );
                      }
                    '';
                  };
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
      botocore = inputs.pythonOnNix.projectsMeta.botocore;
      django = inputs.pythonOnNix.projectsMeta.django;
    });
in
makeScript {
  name = "generate-data";
  entrypoint = ./entrypoint.sh;
  replace = {
    __argProjectsList__ = __nixpkgs__.linkFarm "projects" (builtins.map
      (project: {
        name = project;
        path = projects.${project};
      })
      (builtins.attrNames projects));
  };
}
