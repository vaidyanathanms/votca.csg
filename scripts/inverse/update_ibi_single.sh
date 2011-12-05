#! /bin/bash
#
# Copyright 2009-2011 The VOTCA Development Team (http://www.votca.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [ "$1" = "--help" ]; then
cat <<EOF
${0##*/}, version %version%
This script implemtents the function update for a single pair
for the Inverse Boltzmann Method

Usage: ${0##*/}
EOF
   exit 0
fi

step_nr=$(get_current_step_nr)
scheme=( $(csg_get_interaction_property inverse.do_potential) )
scheme_nr=$(( ($step_nr - 1 ) % ${#scheme[@]} ))
name=$(csg_get_interaction_property name)

if [ "${scheme[$scheme_nr]}" = 1 ]; then
   echo "Update potential ${name} : yes"
   #update ibi
   do_external resample target "$(csg_get_interaction_property inverse.target)" "${name}.dist.tgt"
   do_external update ibi_pot ${name}.dist.tgt ${name}.dist.new ${name}.pot.cur ${name}.dpot.pure_ibi
   do_external dpot shift_nonbonded ${name}.dpot.pure_ibi ${name}.dpot.new
else
   echo "Update potential ${name} : no"
   min=$(csg_get_interaction_property min)
   step=$(csg_get_interaction_property step)
   max=$(csg_get_interaction_property max)
   do_external table dummy ${min}:${step}:${max} ${name}.dpot.new
fi
