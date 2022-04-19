{inputs, ...}: {
  inputs = {
    prod = true;

    pythonOnNixRef = "main";
    pythonOnNixRev = "d8a7fa21b76ac3b8a1a3fedb41e86352769b09ed";
    pythonOnNixUrl = "https://github.com/on-nix/python";
    pythonOnNix =
      import
      (builtins.fetchGit {
        ref = inputs.pythonOnNixRef;
        rev = inputs.pythonOnNixRev;
        url = inputs.pythonOnNixUrl;
      })
      {};
  };
}
