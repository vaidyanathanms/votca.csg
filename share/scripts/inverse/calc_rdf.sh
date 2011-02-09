#! /bin/bash
#
# Copyright 2009 The VOTCA Development Team (http://www.votca.org)
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
This script implemtents the function initialize for the PMF calculator

Usage: ${0##*/}

USES: do_external csg_get_interaction_property check_deps

NEEDS: pullgroup0 pullgroup1 pullgroup0_type pullgroup1_type confin min max step dt rate kB
EOF
  exit 0
fi

check_deps "$0"

if [ -f ${CSGSHARE}/scripts/inverse/functions_pmf.sh ]; then
  source ${CSGSHARE}/scripts/inverse/functions_pmf.sh || die "Could not source functions_pmf.sh"
else
  die "Could not find functions_pmf.sh"
fi

potfile="pmf_${pullgroup0}_${pullgroup1}.d"
rdffile="rdf_${pullgroup0}_${pullgroup1}.d"
kB="8.31451e-3"

temp="$(get_from_mdp ref_t ${sim}/grompp.mdp)"
echo "Calculating rdf"
echo "Found temp $temp K"
echo "Using kB $kB"
echo "#r rdf" > ${rdffile}
awk  -v temp="$temp" -v kB="$kB" '/^[^@#]/{print $1,exp(-$2/temp/kB)}' ${potfile} >> ${rdffile}
