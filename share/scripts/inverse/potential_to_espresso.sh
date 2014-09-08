#!/bin/bash
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
This script is a wrapper to convert a potential to espresso

Usage: ${0##*/}
EOF
  exit 0
fi

name=$(csg_get_interaction_property name)
input="${name}.pot.cur"

output="$(csg_get_interaction_property inverse.espresso.table)"
echo "Convert $input to $output"

r_cut=$(csg_get_interaction_property max)
espresso_bins="$(csg_get_property cg.inverse.espresso.table_bins)"

comment="$(get_table_comment)"

critical csg_resample --in ${input} --out smooth_${input} --der smooth_dpot_${input} --grid 0:${espresso_bins}:${r_cut} --comment "$comment"
do_external convert_potential tab smooth_${input} smooth_dpot_${input} ${output}
