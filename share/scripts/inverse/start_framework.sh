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
this script starts the iterative framework and performs a lot of tests

PROVIDES: \$CSGXMLFILE \$CSGINVERSE \$SOURCE_WRAPPER \$CSGSCRIPTDIR \$CSG_MASTER_PID

USES: \$CSGSHARE die 

EOF
  exit 0
fi

#no check deps $0 here
#because this bootstrap everything

#for now, we will replace this function later
die(){ echo "$*" >&2; exit 1; }

#check for CSGSHARE
[[ -n "$CSGSHARE" ]] || die "Error: CSGSHARE not definded"
[[ -d "$CSGSHARE" ]] || die "CSGSHARE '$CSGSHARE' is not a dir"

CSGINVERSE="${CSGSHARE}/scripts/inverse"
[[ -d "$CSGINVERSE" ]] || die "\$CSGSHARE/scripts/inverse is not a dir"
[ -f "${CSGSHARE}/scripts/inverse/inverse.sh" ] || die "inverse.sh not found"
export CSGINVERSE
export PERL5LIB="$CSGINVERSE:$PERL5LIB"

#find source_wrapper.pl
SOURCE_WRAPPER="${CSGINVERSE}/source_wrapper.pl"
[[ -x "${SOURCE_WRAPPER}" ]] || die "Could not find source_wrapper.pl"
export SOURCE_WRAPPER

#this is need by die later
export CSG_MASTER_PID="$$"

function_file=$($SOURCE_WRAPPER functions common) || die "$SOURCE_WRAPPER functions common failed"
#die() is overwritten here
source ${function_file} || exit 1
unset function_file

export CSG_MAINDIR="$PWD"
