{ inputs
, ...
}:
{
  inputs = {
    prod = true;

    pythonOnNixRef = "main";
    pythonOnNixRev = "0e712f09e8d9ddd7519c9c0ae7fd2a6bc837b7ff";
    pythonOnNixUrl = "https://github.com/on-nix/python";
    pythonOnNix = import
      (builtins.fetchGit {
        ref = inputs.pythonOnNixRef;
        rev = inputs.pythonOnNixRev;
        url = inputs.pythonOnNixUrl;
      })
      { };
  };
}
