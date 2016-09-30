#!/bin/bash

function git-show-gerrit() {
  while read c; do
    # print ChangeId
    echo -n $(git show "$c" -s | grep 'Change-Id:' | sed 's/.*Change-Id: \(.*\)/\1/' )
    # print shortened SHA, author name, subject
    git show -s --format='format:;%h;%an;%s;' "$c" | cat
    # print Gerrit URL
    git show "$c" -s --notes=refs/notes/review | grep 'Reviewed-on:' | cut -d ' ' -f 6
  done
}

function git-show-gerrit-nomerge() {
  while read c; do
    if git show -s "$c" | grep -q '^Merge:'; then
      continue
    fi

    echo "$c" | git-show-gerrit
  done
}

# Check the presence of a given set of commits in another branch
#
# Check all the commits in the ]$1, $2] window, and report whether
# 'similar' (as in git-cherry) commits appear in anything reachable
# from another branch, $3 (more specifically, $2..$3). Additionally,
# check if there is a port-by-changeID match in the other branch.
#
# $1: the ancestor of the first commit to check
# $2: the top of the local branch to check commits
# $3: the other branch to check commits into
function git-check-branch-presence() {
  if [[ $# -ne 3 ]]; then
    echo "${FUNCNAME} needs 3 parameters:"
    echo ' $1: the ancestor of the first commit to check'
    echo ' $2: the top of the local branch to check commits'
    echo ' $3: the other branch to check commits into'
    return
  fi
  echo "Checking whether all commits in '$1..$2' are in '$3':" >&2
  echo >&2

  local tmpfilename="/tmp/${FUNCNAME}-$$"
  : > "${tmpfilename}"
  git log "${2}..${3}" > "${tmpfilename}"

  # echo the header
  echo "Port status;Change-Id;Hash;Author;Subject;Link"
  # note to self: git cherry already elides merge commits
  git cherry "$3" "$2" "$1" | while read line; do
    local state=$(echo "${line}" | cut -f 1 -d ' ')
    local id=$(echo "${line}" | cut -f 2 -d ' ')

    if [[ "$state" == '-' ]]; then
      echo -n "PORTED;"
    else
      # check if, by any chance, this commit was ported-by-changeID
      local src_changeid=$(git show "$id" -s | grep 'Change-Id:' | sed 's/.*Change-Id: \(.*\)/\1/')
      if grep -q "Change-Id: ${src_changeid}$" "${tmpfilename}"; then
        # commit has a changeID correspondant
        echo -n "PORTED-BY-CHANGEID;"
      else
        echo -n "MISSING;"
      fi
    fi
    echo "${id}" | git-show-gerrit
  done

  rm -f "${tmpfilename}"
}

# Port a list of commits into the current branch.
#
# $1: input file with list of commits to cherry-pick
# $2: input file with list of hints, in the form "originalSHA:cherrypickableSHA"
# $3: output file with SHA of all successful cherrypicks
# $4: output file with SHA of all failed cherrypicks
# $5: (optional) if present, stop at the first failure
function git-batch-port() {
  if [[ $# -lt 4 ]]; then
    echo "${FUNCNAME} needs 4 parameters:"
    echo '  $1: input file with list of commits to cherry-pick'
    echo '  $2: input file with list of hints, in the form "originalSHA:cherrypickableSHA"'
    echo '  $3: output file with SHA of all successful cherrypicks'
    echo '  $4: output file with SHA of all failed cherrypicks'
    echo '  $5: (optional) if present, stop at the first failure'
    return
  fi

  local input_commits="$1"
  local input_hints="$2"
  local output_ok="$3"
  local output_fail="$4"

  echo "Checking whether all commits in '${input_commits}' can be cleanly applied."
  echo "Hint file: '${input_hints}'"
  echo "Successful out: '${output_ok}'"
  echo "Failed out: '${output_fail}'"
  echo

  if [[ ! -r "${input_commits}" ]] ; then
    echo -e "\033[01;31mInput file '${input_commits}' not found\033[00m"
    return
  fi

  if [[ ! -r "${input_hints}" ]] ; then
    echo -e "\033[01;31mInput file '${input_hints}' not found\033[00m"
    return
  fi

  : > "${output_ok}"
  : > "${output_fail}"
  while read c; do
    echo -e "\033[01;32m+ Trying to apply:\033[00m ${c}"

    # check if we have a hint first
    local hint=$(grep "^${c}:" "${input_hints}" | cut -f 2 -d ':')
    if [[ -n "${hint}" ]]; then
      echo -e "\033[01;32m++ Using hint:\033[00m ${hint}"
      commit="${hint}"
    else
      commit="${c}"
    fi

    local dashx="-x"
    if [[ -n "${hint}" ]]; then
      # do not use -x if using a hint - the wrong hash would be referenced
      dashx=""
    fi
    git cherry-pick $dashx "${commit}"
    status=$?
    if [[ ${status} -eq 0 ]]; then
      echo "${commit}" >> "${output_ok}"
    else
      echo "${commit}" >> "${output_fail}"
      if [[ -n "${5}" ]]; then
        echo -e "\033[01;31m!! Failed to apply\033[00m ${commit}\033[01;31m, stopping as requested\033[00m"
        return
      fi
      echo -e "\033[01;31m!! Failed to apply\033[00m ${commit}, undoing cherry-pick attempt"
      git cherry-pick --abort
    fi
  done < "${input_commits}"

  echo
  echo "$(wc -l ${input_commits} | cut -f 1 -d ' ') cherry-picks attempted"
  echo "$(wc -l ${output_ok} | cut -f 1 -d ' ') cherry-picks successful"
  echo "$(wc -l ${output_fail} | cut -f 1 -d ' ') cherry-picks failed"
}

# Filter out commits from a list, whose changeid appears in the git
# log between two commits ($2..$3)
#
# $1: input file with list of commits to check
# $2: initial commit of the window to check into
# $3: last commit of the window to check into
# $4: output file with SHA of all commits without a correspondent
# $5: output file with SHA of all commits with a correspondent
function git-filter-by-changeid() {
  if [[ $# -ne 5 ]]; then
    echo "${FUNCNAME} needs 3 parameters:"
    echo '  $1: input file with list of commits to check'
    echo '  $2: initial commit of the window to check into'
    echo '  $3: last commit of the window to check into'
    echo '  $4: output file with SHA of all commits without a correspondent'
    echo '  $5: output file with SHA of all commits with a correspondent'
    return
  fi

  local input_commits="$1"
  local first_commit="$2"
  local last_commit="$3"
  local output_nocorrespond="$4"
  local output_withcorrespond="$5"

  echo "Filtering commits out of '${input_commits}', that have a change-id correspondence in " \
       "'${first_commit}..${last_commit}'"
  echo "File with commits without correspondant: ${output_nocorrespond}"
  echo "File with commits with correspondant: ${output_withcorrespond}"

  local tmpfilename="/tmp/git-filter-by-changeid-$$"
  : > "${tmpfilename}"
  git log "${first_commit}..${last_commit}" > "${tmpfilename}"

  : > "${output_nocorrespond}"
  : > "${output_withcorrespond}"
  while read c; do
    local src_changeid=$(git show "$c" -s | grep 'Change-Id:' | sed 's/.*Change-Id: \(.*\)/\1/')
    if grep -q "Change-Id: ${src_changeid}$" "${tmpfilename}"; then
      # commit has a correspondant
      echo "${c}" >> "${output_withcorrespond}"
    else
      # change id not found, cannot filter this commit out
      echo "${c}" >> "${output_nocorrespond}"
    fi
  done < "${input_commits}"

  rm -f "${tmpfilename}"
  echo
  echo "$(wc -l ${input_commits} | cut -f 1 -d ' ') commits tested"
  echo "$(wc -l ${output_nocorrespond} | cut -f 1 -d ' ') commits without correspondant"
  echo "$(wc -l ${output_withcorrespond} | cut -f 1 -d ' ') commits with correspondant"
}
