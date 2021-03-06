#!/bin/bash
#
#    Provide continuous printout of ping latency and current timestamp
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

function pingloop() {
    while ping 8.8.8.8; do
	sleep 1
    done
}

function tsloop() {
    while date; do
	sleep 10
    done
}

tsloop &
PID1=$!
pingloop &
PID2=$!
echo "Waiting for PIDs ${PID1} and ${PID2} ..." >&2
wait "${PID1}" "${PID2}"
echo "Done waiting." >&2
