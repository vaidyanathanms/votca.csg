package CsgFunctions;
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

use strict;

require Exporter;

use vars qw(@ISA @EXPORT);
@ISA         = qw(Exporter);
@EXPORT      = qw(csg_function_help csg_get_property csg_get_interaction_property readin_table readin_data saveto_table saveto_table_err readin_table_err);

sub csg_function_help() {
  print <<EOF;
CsgFunctions, version %version%
Provides useful function for perl:
csg_get_property(\$;\$):             get a value from xml file
csg_get_interaction_property(\$;\$): get a interaction property from xmlfile
readin_table(\$\\@\\@\\@;\\\$):           reads in csg table
readin_table_err(\$\\@\\@\\@;\\\$):           reads in csg table with errors
saveto_table(\$\\@\\@\\@;\$):           writes to a csg table
saveto_table_err(\$\\@\\@\\@;\$) :      writes to csg table with errors
EOF
  exit 0;
}

sub csg_get_property($;$){
  ( my $xmlfile=$ENV{'CSGXMLFILE'} ) || die "csg_get_property: ENV{'CSGXMLFILE'} was undefined\n";
  defined($_[0]) || die "csg_get_property: Missing argument\n";
  open(CSG,"csg_property --file $xmlfile --path $_[0] --short --print . |") ||
    die "csg_get_property: Could not open pipe\n";
  my $value=<CSG>;
  while(<CSG>){
    $value.=$_;
  }
  $value="$_[1]" if ((not defined($value)) and defined($_[1]));
  defined($value) || die "csg_get_property: Could not get value $_[0] and no default given\n";
  close(CSG) || die "csg_get_property: error from csg_property\n";
  $value =~ s/\n/ /mg;
  $value =~ s/^\s*//;
  $value =~ s/\s*$//;
  return undef if ($value =~ /^\s*$/);
  return $value;
}

sub csg_get_interaction_property($;$){
  ( my $bondname=$ENV{'bondname'} ) || die "bondname: ENV{'bondname'} was undefined\n";
  ( my $bondtype=$ENV{'bondtype'} ) || die "bondtype: ENV{'bondtype'} was undefined\n";
  ( my $xmlfile=$ENV{'CSGXMLFILE'} ) || die "csg_get_property: ENV{'CSGXMLFILE'} was undefined\n";
  defined($_[0]) || die "csg_get_interaction_property: Missing argument\n";
  open(CSG,"csg_property --file $xmlfile --short --path cg.$bondtype --filter \"name=$bondname\" --print $_[0] 2>&1 |") ||
    die "csg_get_interaction_property: Could not open pipe\n";
  my $value=<CSG>;
  while(<CSG>){
    $value.=$_;
  }
  if (close(CSG)){
    #we do not have a return errors
    $value="$_[1]" if (($value =~ /^\s*$/) and (defined($_[1])));
  } else {
    #we do have a return errors
    if (defined($_[1])) {
      $value="$_[1]";
    } else {
      die "csg_get_interaction_property: csg_property failed on getting value $_[0] and no default given\n";
    }
  }
  $value =~ s/\n/ /mg;
  $value =~ s/^\s*//;
  $value =~ s/\s*$//;
  return undef if ($value =~ /^\s*$/);
  return $value;
}

sub readin_table($\@\@\@;\$) {
  defined($_[3]) || die "readin_table: Missing argument\n";
  open(TAB,"$_[0]") || die "readin_table: could not open file $_[0]\n";
  my $line=0;
  while (<TAB>){
    $line++;
    ${$_[4]}.=$_ if (defined($_[4]) and (/^[#@]/));
    next if /^[#@]/;
    # remove leading spacees for split
    $_ =~ s/^\s*//;
    next if /^\s*$/;
    my @parts=split(/\s+/);
    defined($parts[2]) || die "readin_table: Not enought columns in line $line in file $_[0]\n";
    ($parts[$#parts] =~ /[iou]/) || die "readin_table: Wrong flag($parts[$#parts]) for r=$parts[0] in file $_[0]\n";
    #very trick array dereference (@) of pointer to an array $_[.] stored in an array $_
    push(@{$_[1]},$parts[0]);
    push(@{$_[2]},$parts[1]);
    push(@{$_[3]},$parts[$#parts]);
  }
  close(TAB) || die "readin_table: could not close file $_[0]\n";
  return $line;
}

sub readin_table_err($\@\@\@\@;\$) {
  defined($_[4]) || die "readin_table_err: Missing argument\n";
  open(TAB,"$_[0]") || die "readin_table_err: could not open file $_[0]\n";
  my $line=0;
  while (<TAB>){
    $line++;
    ${$_[5]}.=$_ if (defined($_[4]) and (/^[#@]/));
    # remove leading spacees for split
    $_ =~ s/^\s*//;
    next if /^[#@]/;
    next if /^\s*$/;
    my @parts=split(/\s+/);
    defined($parts[3]) || die "readin_table_err: Not enought columns in line $line in file $_[0]\n";
    ($parts[$#parts] =~ /[iou]/) || die "readin_table_err: Wrong flag($parts[$#parts]) for r=$parts[0] in file $_[0]\n";
    #very trick array dereference (@) of pointer to an array $_[.] stored in an array $_
    push(@{$_[1]},$parts[0]);
    push(@{$_[2]},$parts[1]);
    push(@{$_[3]},$parts[2]);
    push(@{$_[4]},$parts[$#parts]);
  }
  close(TAB) || die "readin_table_err: could not close file $_[0]\n";
  return $line;
}

sub readin_data($$\@\@) {
  defined($_[3]) || die "readin_data: Missing argument\n";
  open(TAB,"$_[0]") || die "readin_table: could not open file $_[0]\n";
  my $line=0;
  my $column=int($_[1]);
  while (<TAB>){
    $line++;
    # remove leading spacees for split
    $_ =~ s/^\s*//;
    next if /^[#@]/;
    next if /^\s*$/;
    my @parts=split(/\s+/);
    defined($parts[1]) || die "readin_table: Not enought columns in line $line in file $_[0]\n";
    die "readin_data: Can't read column $column\n" unless (defined($parts[$column]));
    #very trick array dereference (@) of pointer to an array $_[.] stored in an array $_
    push(@{$_[2]},$parts[0]);
    push(@{$_[3]},$parts[$column]);
  }
  close(TAB) || die "readin_table: could not close file $_[0]\n";
  return $line;
}

sub saveto_table($\@\@\@;$) {
  defined($_[3]) || die "saveto_table: Missing argument\n";
  open(OUTFILE,"> $_[0]") or die "saveto_table: could not open $_[0] \n";
  print OUTFILE "$_[4]" if (defined $_[4]);
  for(my $i=0;$i<=$#{$_[1]};$i++){
    print OUTFILE "${$_[1]}[$i] ${$_[2]}[$i] ${$_[3]}[$i]\n";
  }
  close(OUTFILE) or die "Error at closing $_[0]\n";
  return 1;
}

sub saveto_table_err($\@\@\@\@;$) {
  defined($_[3]) || die "saveto_table: Missing argument\n";
  open(OUTFILE,"> $_[0]") or die "saveto_table: could not open $_[0] \n";
  print OUTFILE "$_[5]" if (defined $_[5]);
  for(my $i=0;$i<=$#{$_[1]};$i++){
    print OUTFILE "${$_[1]}[$i] ${$_[2]}[$i] ${$_[3]}[$i] ${$_[4]}[$i]\n";
  }
  close(OUTFILE) or die "Error at closing $_[0]\n";
  return 1;
}

#important
1;
