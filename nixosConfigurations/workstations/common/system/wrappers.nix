{ wrappers, ... }: {
  imports = map (wrapper: wrapper.install) (with wrappers; [
    triad
    git
  ]);

  wrappers = {
    triad.enable = true;
    git.enable = true;
  };
}
