# shellcheck shell=bash

function main {
  : && rm -rf content/projects/* \
    && rm -rf data/projects/* \
    && mkdir -p content/projects \
    && mkdir -p data/projects/by_name \
    && mkdir -p data/projects/by_tree \
    && for projectPath in __argData__/projects/by_name/*; do
      : && project="$(basename "${projectPath}")" \
        && cp "${projectPath}" "data/projects/by_name/${project}.json" \
        || return 1
    done \
    && for projectPath in __argData__/projects/by_tree/*; do
      for versionPath in "${projectPath}/"*; do
        for pythonVersionPath in "${versionPath}/"*; do
          : && project="$(basename "${projectPath}")" \
            && version="$(basename "${versionPath}")" \
            && pythonVersion="$(basename "${pythonVersionPath}")" \
            && index="${project}-${version}-${pythonVersion}" \
            && path="${project}/${version}/${pythonVersion}" \
            && echo --- > "content/projects/${index}.md" \
            && echo "index: ${index}" >> "content/projects/${index}.md" \
            && echo "project: ${project}" >> "content/projects/${index}.md" \
            && echo "version: ${version}" >> "content/projects/${index}.md" \
            && echo "pythonVersion: ${pythonVersion}" >> "content/projects/${index}.md" \
            && echo --- >> "content/projects/${index}.md" \
            && cp "${pythonVersionPath}" "data/projects/by_tree/${index}.json" \
            || return 1
        done
      done
    done
}

main "${@}"
