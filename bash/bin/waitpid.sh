#!/bin/bash
#
#    Wait for a PID to terminate
#    Copyright (C) 2024  Marco Leogrande
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

[[ $# -lt 1 ]] && echo 'No PID to wait for.' && exit 1

tail --pid="${1}" -s 10 -f /dev/null
