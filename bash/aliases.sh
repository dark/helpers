#!/bin/bash
#
#    Generic Bash aliases
#    Copyright (C) 2017  Marco Leogrande
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Import the bin/ subdirectory as part of the PATH.
SCRIPTDIR=$(readlink -e "$(dirname "${BASH_SOURCE[0]}")" )
if [[ -n "${SCRIPTDIR}" ]]; then
  if ! echo "${PATH}" | grep -q ":${SCRIPTDIR}/bin/"; then
    export PATH="${PATH}:${SCRIPTDIR}/bin/"
  fi
else
  echo "${BASH_SOURCE[0]} did not point to anything useful"
fi
unset SCRIPTDIR

# aliases ...
alias ps-full='ps -eHo euser,pid,tid,ppid,pgrp,ni,psr,pcpu,pmem,cputime,rss,vsz,stat,start,wchan:20,args'
alias xopen='xdg-open'
alias ssh-nomem='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
