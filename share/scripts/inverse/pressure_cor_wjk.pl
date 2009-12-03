#! /usr/bin/perl -w

use strict;
( my $progname = $0 ) =~ s#^.*/##;
if (defined($ARGV[0])&&("$ARGV[0]" eq "--help")){
  print <<EOF;
Usage: $progname p_cur outfile
This script calls the pressure corrections  like in 
Wan, Junghans & Kremer, Euro. Phys. J. E 28, 221 (2009) 

NEEDS: cg.inverse.kBT max step inverse.particle_dens inverse.p_target name
USES: csg_get_property csg_get_interaction_property saveto_table readin_table
EOF
  exit 0;
}

die "2 parameters are nessary\n" if ($#ARGV<1);


use CsgFunctions;

my $kBT=csg_get_property("cg.inverse.kBT");
my $max=csg_get_interaction_property("max");
my $delta_r=csg_get_interaction_property("step");

my $partDens=csg_get_interaction_property("inverse.particle_dens");
my $name=csg_get_interaction_property("name");

my $pi= 3.14159265;
my $bar_to_SI = 0.06022; # 1bar=0.06022 kJ/(nm mol)

my $p_target=csg_get_interaction_property("inverse.p_target");
my $p_now=$ARGV[0];

# load current rdf
my $cur_rdf_file="${name}.dist.new";
my @r_cur;
my @rdf_cur;
my @flags_cur;

(readin_table($cur_rdf_file,@r_cur,@rdf_cur,@flags_cur)) || die "$progname: error at readin_table\n";

# calculate prefactor from rdf
my $integral=0.0;
my $x;
for(my $i=1;$i<$max/$delta_r;$i++){ 
	$x=$i*$delta_r;
	$integral+=$x*$x*$x*$delta_r*$rdf_cur[$i];
}
my $pref;

$integral += ($delta_r/2*$rdf_cur[$max/$delta_r]*$max*$max*$max);
$pref = -3*$max*($p_now-$p_target)*$bar_to_SI;
$pref /= 2*$pi*$partDens*$partDens*$integral;

# use max($pref, +-0.1kt) as prefactor

my $temp;
$temp=$pref;
$temp = -1*$temp if $temp<0; 
if ($temp > 0.1*$kBT){
	if ($pref >0){
		$pref=0.1*$kBT;
	}else{
		$pref=-0.1*$kBT;
	}
}

print "Pressure correction factor: A=$pref\n";

my @r;
my @pot;
my @flag;
my $outfile="$ARGV[1]";
for(my $i=0;$i<=$max/$delta_r;$i++){
  $r[$i]=$i*$delta_r;
  $pot[$i]=$pref*(1-$r[$i]/$max);
  $flag[$i]="i";
}
saveto_table($outfile,@r,@pot,@flag) || die "$progname: error at save table\n";

