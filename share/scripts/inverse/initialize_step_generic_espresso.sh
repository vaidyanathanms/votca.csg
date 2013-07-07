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

if [[ $1 = "--help" ]]; then
cat <<EOF
${0##*/}, version %version%
This script initializes an espresso simulation

Usage: ${0##*/}
EOF
   exit 0
fi

from=$(csg_get_property cg.inverse.initial_configuration)
esp="$(csg_get_property cg.inverse.espresso.blockfile)"
if [[ $from = "laststep" ]]; then
  espout="$(csg_get_property cg.inverse.espresso.blockfile_out)"
  #avoid overwriting $espout
  cp_from_last_step --rename "$espout" "$esp"
elif [[ $from = "maindir" ]]; then
  cp_from_main_dir $esp
else
  die "${0##*/}: initial_configuration '$from' not implemented"
fi

#convert potential in format for sim_prog
for_all "non-bonded bonded" do_external convert_potential espresso '$(csg_get_interaction_property name).pot.cur $(csg_get_interaction_property inverse.espresso.table)'
