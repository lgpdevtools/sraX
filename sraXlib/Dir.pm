#!/usr/bin/env perl
package sraXlib::Dir;
use strict;
use warnings;
use sraXlib::Functions;

sub build_dir_str {
my $out_dir = shift;

	system ("mkdir -p $out_dir/ARG_DB") == 0 or die "creating '$out_dir/ARG_DB' failed\n";
	
	system ("mkdir -p $out_dir/Analysis/Homology_Search/Individual_ARGs") == 0 or die "creating '$out_dir/Analysis/Homology_Search/Individual_ARGs' failed\n";
	system ("mkdir -p $out_dir/Analysis/Homology_Search/Individual_Genomes") == 0 or die "creating '$out_dir/Analysis/Homology_Search/Individual_Genomes' failed\n";
	system ("mkdir -p $out_dir/Analysis/MSA/DNA/SNP") == 0 or die "creating '$out_dir/Analysis/MSA/DNA/SNP' failed\n";
        system ("mkdir -p $out_dir/Analysis/MSA/AA/SNP") == 0 or die "creating '$out_dir/Analysis/MSA/AA/SNP' failed\n";

	system ("mkdir -p $out_dir/Results/Plots/Heatmaps") == 0 or die "creating '$out_dir/Results/Plots/Heatmaps' failed\n";
	system ("mkdir -p $out_dir/Results/Plots/Proportion_ARG") == 0 or die "creating '$out_dir/Results/Plots/Proportion_ARG' failed\n";
	system ("mkdir -p $out_dir/Results/Plots/Genomic_Context") == 0 or die "creating '$out_dir/Results/Plots/Genomic_Context' failed\n";
	system ("mkdir -p $out_dir/Results/Summary_files") == 0 or die "creating '$out_dir/Results/Summary_files' failed\n";

	system ("mkdir $out_dir/tmp") == 0 or die "creating '$out_dir/tmp' failed\n";
	system ("mkdir $out_dir/Log") == 0 or die "creating '$out_dir/Log' failed\n";

}
 
1;
