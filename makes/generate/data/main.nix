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
                      tryItOut.stable = ''
                        $ nix-shell \
                          --attr 'projects."${project}"."${version}".${pythonVersion}.dev' \
                          '${inputs.pythonOnNixUrl}/tarball/${inputs.pythonOnNixRev}'
                      '';
                      tryItOut.flakes = ''
                        $ nix develop \
                          'github:on-nix/python/${inputs.pythonOnNixRev}#"${project}-${version}-${pythonVersion}"'
                      '';
                      installApps.stable = ''
                        $ nix-env --install \
                          --attr 'apps."${project}"."${version}"' \
                          --file '${inputs.pythonOnNixUrl}/tarball/${inputs.pythonOnNixRev}'
                      '';
                      installApps.flakes = ''
                        $ nix profile install \
                          'github:on-nix/python#"${project}-${version}-${pythonVersion}-bin"'
                      '';
                      many.stable = ''
                        # Save this file as: ./example.nix

                        let
                          # Import Nixpkgs
                          nixpkgs = import <nixpkgs> { };

                          # Import Python on Nix
                          pythonOnNix = import
                            (builtins.fetchGit {
                              ref = "${inputs.pythonOnNixRef}";
                              rev = "${inputs.pythonOnNixRev}";
                              url = "${inputs.pythonOnNixUrl}";
                            })
                            { inherit nixpkgs; };

                          env = pythonOnNix.${pythonVersion}Env {
                            name = "example";
                            projects = {
                              "${project}" = "${version}";
                              # You can add more projects here as you need
                              # "a" = "1.0";
                              # "b" = "2.0";
                              # ...
                            };
                          };

                          # `env` has two attributes:
                          # - dev: The activation script for the Python on Nix environment
                          # - out: The raw contents of the Python site-packages
                        in
                        {
                          # The activation script can be used as dev-shell
                          shell = env.dev;

                          # You can also use with Nixpkgs
                          example = nixpkgs.stdenv.mkDerivation {
                            # Let's use the activation script as build input
                            # so the Python environment is loaded
                            buildInputs = [ env.dev ];

                            builder = builtins.toFile "builder.sh" '''
                              source $stdenv/setup

                              # ${project} will be available here!

                              touch $out
                            ''';
                            name = "example";
                          };
                        }

                        # Usage:
                        #
                        #   Dev Shell:
                        #     $ nix-shell --attr shell ./example.nix
                        #
                        #   Build example:
                        #     $ nix-build --attr example ./example.nix
                      '';
                      many.flakes = ''
                        # Save this file as: ./flake.nix

                        {
                          inputs = {
                            flakeUtils.url = "github:numtide/flake-utils";
                            nixpkgs.url = "github:nixos/nixpkgs";
                            pythonOnNix.url = "github:on-nix/python/${inputs.pythonOnNixRev}";
                            pythonOnNix.inputs.nixpkgs.follows = "nixpkgs";
                          };
                          outputs = { self, ... } @ inputs:
                            inputs.flakeUtils.lib.eachSystem [ "x86_64-linux" ] (system:
                              let
                                nixpkgs = inputs.nixpkgs.legacyPackages.''${system};
                                pythonOnNix = inputs.pythonOnNix.lib.''${system};

                                env = pythonOnNix.${pythonVersion}Env {
                                  name = "example";
                                  projects = {
                                    "${project}" = "${version}";
                                    # You can add more projects here as you need
                                    # "a" = "1.0";
                                    # "b" = "2.0";
                                    # ...
                                  };
                                };
                                # `env` has two attributes:
                                # - dev: The activation script for the Python on Nix environment
                                # - out: The raw contents of the Python site-packages
                              in
                              {
                                devShells = {

                                  # The activation script can be used as dev-shell
                                  shell = env.dev;

                                };

                                packages = {

                                  # You can also use with Nixpkgs
                                  example = nixpkgs.stdenv.mkDerivation {
                                    # Let's use the activation script as build input
                                    # so the Python environment is loaded
                                    buildInputs = [ env.dev ];
                                    virtualEnvironment = env.out;

                                    builder = builtins.toFile "builder.sh" '''
                                      source $stdenv/setup

                                      # ${project} will be available here!

                                      touch $out
                                    ''';
                                    name = "example";
                                  };

                                };
                              }
                            );
                        }

                        # Usage:
                        #   First add your changes:
                        #     $ git add flake.nix
                        #
                        #   Dev Shell:
                        #     $ nix develop .#shell
                        #
                        #   Build example:
                        #     $ nix build .#example
                      '';
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
