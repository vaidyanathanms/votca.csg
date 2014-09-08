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

show_help () {
  cat << eof
${0##*/}, version %version%

Start the script to run ibi, imc, etc. or clean out current dir

Usage: ${0##*/} [OPTIONS] --options settings.xml [clean]

Allowed options:
-h, --help                    show this help
-N, --do-iterations N         only do N iterations
    --wall-time SEK           Set wall clock time
    --options FILE            Specify the options xml file to use
    --debug                   enable debug mode with a lot of information
    --nocolor                 disable colors

Examples:
* ${0##*/} --options cg.xml
* ${0##*/} -6 --options cg.xml
eof
}

#--help should always work so leave it here
if [[ $1 = "--help" ]]; then
  show_help
  exit 0
fi

#do all start up checks option stuff
source "${0%/*}/start_framework.sh"  || exit 1

#defaults for options
do_iterations=""

#unset stuff from enviorment
unset CSGXMLFILE CSGENDING CSGDEBUG

### begin parsing options
shopt -s extglob
while [[ ${1#-} != $1 ]]; do
 if [[ ${1#--} = $1 && -n ${1:2} ]]; then
    #short opt with arguments here: fc
    if [[ ${1#-[fc]} != ${1} ]]; then
       set -- "${1:0:2}" "${1:2}" "${@:2}"
    else
       set -- "${1:0:2}" "-${1:2}" "${@:2}"
    fi
 fi
 case $1 in
   --do-iterations)
    do_iterations="$2"
    int_check "$do_iterations" "inverse.sh: --do-iterations need a number as agrument"
    shift 2 ;;
   --wall-time)
    int_check "$2" "inverse.sh: --wall-time need a number as agrument"
    export CSGENDING=$(( $(get_time) + $2 ))
    shift 2 ;;
   -[0-9]*)
    do_iterations=${1#-}
    shift ;;
   --options)
    CSGXMLFILE="$2"
    [[ -f $CSGXMLFILE ]] || die "options xml file '$CSGXMLFILE' not found"
    export CSGXMLFILE="$(globalize_file "${CSGXMLFILE}")"
    shift 2;;
   --nocolor)
    export CSGNOCOLOR="yes"
    shift;; 
   --debug)
    export CSGDEBUG="yes"
    shift;; 
   -h | --help)
    show_help
    exit 0;;
  *)
   die "Unknown option '$1'";;
 esac
done
### end parsing options

#old style, inform user
[[ -z ${CSGXMLFILE} ]] && die "Please add your setting xml file behind the --options option (like for all other votca programs) !"

[[ $1 = "clean" ]] && { csg_inverse_clean; exit $?; }

enable_logging
[[ -n $CSGDEBUG ]] && set -x
check_for_obsolete_xml_options

echo "Sim started $(date)"

method="$(csg_get_property cg.inverse.method)"
msg "We are doing Method: $method"

sim_prog="$(csg_get_property cg.inverse.program)"
echo "We are using Sim Program: $sim_prog"
source_function $sim_prog

iterations_max="$(csg_get_property cg.inverse.iterations_max)"
int_check "$iterations_max" "inverse.sh: cg.inverse.iterations_max needs to be a number"
echo "We are doing $iterations_max iterations (0=inf)."
convergence_check="$(csg_get_property cg.inverse.convergence_check "none")"
[[ $convergence_check = none ]] || echo "After every iteration we will do the following check: $convergence_check"

filelist="$(csg_get_property --allow-empty cg.inverse.filelist)"
[[ -z $filelist ]] || echo "We extra cp '$filelist' to every step to run the simulation"

cleanlist="$(csg_get_property --allow-empty cg.inverse.cleanlist)"
[[ -z $cleanlist ]] || echo "We extra clean '$cleanlist' after a step is done"

scriptdir="$(csg_get_property --allow-empty cg.inverse.scriptdir)"
[[ -n $scriptdir ]] && add_to_csgshare "$scriptdir"

show_csg_tables

#main script
[[ -f done ]] && { msg "Job is already done (remove the file named 'done' if you want to go on)"; exit 0; }

######## BEGIN STEP 0 ############
update_stepnames 0
restart_file="$(get_restart_file)"
this_dir=$(get_current_step_dir --no-check)
if [[ -d $this_dir &&  -f "$this_dir/done" ]]; then
  msg "step 0 is already done - skipping"
else
  echo ------------------------
  msg --color blue "Prepare (dir ${this_dir##*/})"
  echo ------------------------
  if [[ -d $this_dir ]]; then
    msg "Incomplete step 0"
    [[ -f "${this_dir}/${restart_file}" ]] || die "No restart file found (remove stepdir '${this_dir##*/}' if you don't know what to do - you will lose the prepare step)"
  else
    mkdir -p $this_dir || die "mkdir -p $this_dir failed"
  fi
  cd $this_dir || die "cd $this_dir failed"
  mark_done "stepdir"

  if is_done "Prepare"; then
    msg "Prepare of potentials already done"
  else
    do_external prepare $method
    mark_done "Prepare"
  fi

  touch "done"
  msg "step 0 done"
  cd $(get_main_dir)
fi
######## END STEP 0 ############

begin=1
trunc=$(get_stepname --trunc)
for i in ${trunc}*; do
  [[ -d $i ]] || continue
  nr=${i#$trunc}
  if [[ -n $nr && -z ${nr//[0-9]} ]]; then
    #convert to base 10, otherwise 008 is interpreted as octal
    nr=$((10#$nr))
    [[ $nr -gt $begin ]] && begin="$nr"
  fi
done
unset nr trunc
[[ $begin -gt 1 ]] && msg "Jumping in at iteration $begin"

avg_steptime=0
steps_done=0
[[ $iterations_max -eq 0 ]] && iterations=$begin || iterations=$iterations_max
for ((i=$begin;i<$iterations+1;i++)); do
  [ $iterations_max -eq 0 ] && ((iterations++))
  step_starttime="$(get_time)"
  update_stepnames $i
  last_dir=$(get_last_step_dir)
  this_dir=$(get_current_step_dir --no-check)
  echo -------------------------------
  msg --color blue "Doing iteration $i (dir ${this_dir##*/})"
  echo -------------------------------
  if [[ -d $this_dir ]]; then
    if [[ -f "$this_dir/done" ]]; then
      msg "step $i is already done - skipping"
      continue
    else
      msg "Incomplete step $i"
      [[ -f ${this_dir}/${restart_file} ]] || die "No restart file found (remove stepdir '${this_dir##*/}' if you don't know what to do - you will lose one iteration)"
    fi
  else
    echo "Step $i started at $(date)"
    mkdir -p $this_dir || die "mkdir -p $this_dir failed"
  fi

  cd $this_dir || die "cd $this_dir failed"
  mark_done "stepdir"

  if is_done "Initialize"; then
    echo "Initialization already done"
  else
    #get need files
    cp_from_main_dir "$filelist"

    #get files from last step, init sim_prog and ...
    do_external initstep $method

    mark_done "Initialize"
  fi

  if is_done "Simulation"; then
    echo "Simulation is already done"
  else
    msg "Simulation with $sim_prog"
    do_external run $sim_prog
  fi

  if simulation_finish; then
    mark_done "Simulation"
  elif [ "$(csg_get_property cg.inverse.simulation.background "no")" = "yes" ]; then
    msg "Simulation is suppose to run in background, which we cannot check."
    msg "Stopping now, resume csg_inverse whenever the simulation is done."
    exit 0
  elif [[ -n ${CSGENDING} ]] && checkpoint_exist; then
    msg "Simulation is not finished, but a checkpoint was found, so it seems"
    msg "walltime is nearly up, stopping now, resume csg_inverse whenever you want."
    exit 0
  else
    die "Simulation is in a strange state, it has no checkpoint and is not finished, check ${this_dir##*/} by hand"
  fi

  msg "Make update"
  do_external update $method

  msg "Post update"
  do_external post_update $method

  msg "Adding up potential"
  do_external add_pot $method

  msg "Post add"
  do_external post add

  msg "Clean up"
  for cleanfile in ${cleanlist}; do
    rm -f $cleanfile
  done
  unset cleanfile

  step_time="$(( $(get_time) - $step_starttime ))"
  msg "\nstep $i done, needed $step_time secs"
  ((steps_done++))

  touch "done"

  if [[ $convergence_check = none ]]; then
    echo "No convergence check to be done"
  else
    msg "Doing convergence check: $convergence_check"
    [[ -f stop ]] && rm -f stop
    do_external convergence_check "$convergence_check"
    if [[ -f stop ]]; then
      msg "Iterations are converged, stopping"
      touch "done"
      exit 0
    else
      msg "Iterations are not converged, going on"
    fi
  fi

  if [[ -n $CSGENDING ]]; then
    avg_steptime="$(( ( ( $steps_done-1 ) * $avg_steptime + $step_time ) / $steps_done + 1 ))"
    echo "New average steptime $avg_steptime"
    if [[ $(( $(get_time) + $avg_steptime )) -gt ${CSGENDING} ]]; then
      msg "We will not manage another step, stopping"
      exit 0
    else
      msg "We can go for another $(( ( ${CSGENDING} - $(get_time) ) / $avg_steptime - 1 )) steps"
    fi
  fi

  if [[ -n $do_iterations ]]; then
    if [[ $do_iterations -ge $steps_done ]] ; then
      msg "Stopping at step $i, user requested to take some rest after this amount of iterations"
      exit 0
    else
      msg "Going on for another $(( $do_iterations - $steps_done )) steps"
    fi
  fi
  cd $(get_main_dir) || die "cd $(get_main_dir) failed"
done

touch "done"
echo "All done at $(date)"
exit 0

