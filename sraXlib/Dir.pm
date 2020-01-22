#!/usr/bin/env perl
package sraXlib::Dir;
use strict;
use warnings;
use sraXlib::Functions;

sub build_dir_str {
my $out_dir = shift;

	system ("mkdir -p $out_dir/ARG_DB") == 0 || die sraXlib::Functions::print_errd("$out_dir/ARG_DB");
	
	system ("mkdir -p $out_dir/Analysis/Homology_Search/Individual_ARGs") == 0 || die sraXlib::Functions::print_errd("$out_dir/Analysis/Homology_Search/Individual_ARGs");
	system ("mkdir -p $out_dir/Analysis/Homology_Search/Individual_Genomes") == 0 || die sraXlib::Functions::print_errd("$out_dir/Analysis/Homology_Search/Individual_Genomes");
	system ("mkdir -p $out_dir/Analysis/MSA/DNA/SNP") == 0 || die sraXlib::Functions::print_errd("$out_dir/Analysis/MSA/DNA/SNP"); 
        system ("mkdir -p $out_dir/Analysis/MSA/AA/SNP") == 0 || die sraXlib::Functions::print_errd("$out_dir/Analysis/MSA/AA/SNP");

	system ("mkdir -p $out_dir/Results/Plots/Heatmaps") == 0 || die sraXlib::Functions::print_errd("$out_dir/Results/Plots/Heatmaps");
	system ("mkdir -p $out_dir/Results/Plots/Proportion_ARG") == 0 || die sraXlib::Functions::print_errd("$out_dir/Results/Plots/Proportion_ARG");
	system ("mkdir -p $out_dir/Results/Plots/Genomic_Context") == 0 || die sraXlib::Functions::print_errd("$out_dir/Results/Plots/Genomic_Context");
	system ("mkdir -p $out_dir/Results/Summary_files") == 0 || die sraXlib::Functions::print_errd("$out_dir/Results/Summary_files");

	system ("mkdir $out_dir/tmp") == 0 || die sraXlib::Functions::print_errd("$out_dir/tmp");
	system ("mkdir $out_dir/Log") == 0 || die sraXlib::Functions::print_errd("$out_dir/Log");

}

1;
