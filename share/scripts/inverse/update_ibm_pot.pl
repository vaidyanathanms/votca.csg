#! /usr/bin/perl -w

use strict;
( my $progname = $0 ) =~ s#^.*/##;

if (defined($ARGV[0])&&("$ARGV[0]" eq "--help")){
  print <<EOF;
$progname, version %version%
This script calcs dU out of two rdfs with the rules of inverse boltzman
In addtion it does some magic tricks:
- do not update if one of the both rdf is undefined

Usage: $progname new_rdf target_rdf cur_pot outfile

NEEDS: cg.inverse.kBT

USES: readin_table saveto_table csg_get_property
EOF
  exit 0;
}

die "4 parameters are nessary\n" if ($#ARGV<3);

use CsgFunctions;

my $pref=csg_get_property("cg.inverse.kBT");

my $aim_rdf_file="$ARGV[0]";
my @r_aim;
my @rdf_aim;
my @flags_aim;
(readin_table($aim_rdf_file,@r_aim,@rdf_aim,@flags_aim)) || die "$progname: error at readin_table\n";

my $cur_rdf_file="$ARGV[1]";
my @r_cur;
my @rdf_cur;
my @flags_cur;
(readin_table($cur_rdf_file,@r_cur,@rdf_cur,@flags_cur)) || die "$progname: error at readin_table\n";

my $cur_pot_file="$ARGV[2]";
my @pot_r_cur;
my @pot_cur;
my @pot_flags_cur;
(readin_table($cur_pot_file,@pot_r_cur,@pot_cur,@pot_flags_cur)) || die "$progname: error at readin_table\n";

#should never happen due to resample, but better check
die "Different grids \n" if (($r_aim[1]-$r_aim[0])!=($r_cur[1]-$r_cur[0]));
die "Different start point \n" if (($r_aim[0]-$r_cur[0]) > 0.0);

my $outfile="$ARGV[3]";
my @dpot;
my @flag;

for (my $i=0;$i<=$#r_aim;$i++){
  if (($rdf_aim[$i] > 1e-10) && ($rdf_cur[$i] > 1e-10)) {
    $dpot[$i]=log($rdf_cur[$i]/$rdf_aim[$i])*$pref;
    $flag[$i]="i";
  } else {
    $dpot[$i]="0.0";
    $flag[$i]="u";
  }
  if($pot_flags_cur[$i] =~ /[o]/) {
    $dpot[$i]="0.0";
    $flag[$i]="o";
  }
}

saveto_table($outfile,@r_aim,@dpot,@flag) || die "$progname: error at save table\n";

