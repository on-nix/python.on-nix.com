# shellcheck shell=bash

function main {
  : && rm -rf content/projects/* \
    && rm -rf data/projects/* \
    && mkdir -p content/projects \
    && mkdir -p data/projects \
    && for project in __argProjectsList__/*; do
      : && project="$(basename "${project}")" \
        && echo --- > "content/projects/${project}.md" \
        && echo "project: ${project}" >> "content/projects/${project}.md" \
        && echo --- >> "content/projects/${project}.md" \
        && cp "__argProjectsList__/${project}" "data/projects/${project}.json" \
        || return 1
    done
}

main "${@}"
