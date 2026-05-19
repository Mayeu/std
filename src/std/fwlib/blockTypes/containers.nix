{
  trivial,
  root,
  super,
}:
/*
Use the Containers Blocktype for OCI-images built with nix2container.

Available actions:
  - print-image
  - publish
  - load
*/
let
  inherit (root) mkCommand actions;
  inherit (super) addSelectorFunctor;
  inherit (builtins) readFile toFile;
in
  name: {
    __functor = addSelectorFunctor;
    inherit name;
    type = "containers";
    actions = {
      currentSystem,
      fragment,
      fragmentRelPath,
      target,
      inputs,
    }: let
      inherit (inputs.n2c.packages.${currentSystem}) skopeo-nix2container;
      triv = trivial.${currentSystem};
      # Pin skopeo + jq by absolute store path so the proviso doesn't
      # depend on whatever PATH the discover environment happens to
      # provide.
      proviso = triv.writeShellScript "containers-proviso" ''
        declare action="$1"
        declare image

        eval "$(${triv.jq}/bin/jq -r '@sh "image=\(.meta.image)"' <<<"$action")"

        if ${skopeo-nix2container}/bin/skopeo inspect --insecure-policy "docker://$image" &>/dev/null; then
          exit 1
        fi

        exit 0
      '';

      tags' =
        builtins.toFile "${target.name}-tags.json" (builtins.concatStringsSep "\n" target.image.tags);
      copyFn = ''
        copy() {
          local uri prev_tag
          uri=$1
          shift

          for tag in $(<${tags'}); do
            if ! [[ -v prev_tag ]]; then
              skopeo --insecure-policy copy nix:${target} "$uri:$tag" "$@"
            else
              # speedup: copy from the previous tag to avoid superflous network bandwidth
              skopeo --insecure-policy copy "$uri:$prev_tag" "$uri:$tag" "$@"
            fi
            echo "Done: $uri:$tag"

            prev_tag="$tag"
          done
        }
      '';
    in [
      (actions.build currentSystem target)
      (mkCommand currentSystem "print-image" "print out the image.repo with all tags" [] ''
        echo
        for tag in $(<${tags'}); do
          echo "${target.image.repo}:$tag"
        done
      '' {})
      (mkCommand currentSystem "publish" "copy the image to its remote registry" [skopeo-nix2container] ''
          ${copyFn}
          copy docker://${target.image.repo} "$@"
        '' {
          meta.image = target.image.name;
          inherit proviso;
        })
      (mkCommand currentSystem "load" "load image to the local docker daemon" [skopeo-nix2container] ''
        ${copyFn}
        if command -v podman &> /dev/null; then
           echo "Podman detected: copy to local podman"
           copy containers-storage:${target.image.repo} "$@"
        fi
        if command -v docker &> /dev/null; then
           echo "Docker detected: copy to local docker"
           copy docker-daemon:${target.image.repo} "$@"
        fi
      '' {})
    ];
  }
