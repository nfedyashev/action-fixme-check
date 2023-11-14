#!/bin/sh

# With problem matchers in a container, the matcher config MUST be available
# outside the container on the VM so we will just copy it into the workspace.
# See: https://github.com/actions/toolkit/issues/205#issuecomment-557647948
matcher_path=`pwd`/git-grep-problem-matcher.json
cp /git-grep-problem-matcher.json "$matcher_path"

echo "::add-matcher::git-grep-problem-matcher.json"


case_sensitive="${1}"

if [ ${case_sensitive} = false ]; then
	case_sensitive="--ignore-case"
else
	unset case_sensitive
fi


tag=${INPUT_TERMS:=FIXME}
exclude=${INPUT_EXCLUDE:=FIXME}

exclude_paths=(".github")
if [ -n "$INPUT_EXCLUDE" ]; then
    echo "Variable is set and not null."

    IFS=','
    read -ra exclude_parts <<< "$INPUT_EXCLUDE"
    for el in "${exclude_parts[@]}"
    do
      exclude_paths += ( "$el" )
    done
else
    echo "Variable is either not set or is null."
fi

pathspec=""
for path in "${exclude_paths[@]}"; do
  pathspec+=":^${path} "
done

echo "git grep --no-color ${case_sensitive} --line-number --extended-regexp -e "(${tag})+" ${pathspec}"

result=$(git grep --no-color ${case_sensitive} --line-number --extended-regexp -e "(${tag})+" ${pathspec})

echo "${result}"

if [ -n "${result}" ] && [ "${ENVIRONMENT}" != "test" ]; then
  exit 1
fi
