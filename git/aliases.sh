#!/bin/bash
#
#    Bash aliases for Git directories
#    Copyright (C) 2016  Marco Leogrande
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

alias git-log-pretty='git log --graph --oneline --decorate --date-order --exclude=refs/notes/* --all'
alias git-log-pretty-full='git log --graph --oneline --decorate --date-order --all'
alias git-log-pretty-some='git log --graph --oneline --decorate --date-order'
alias git-log-notes='git log --notes=refs/notes/review'
