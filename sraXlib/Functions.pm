#!/usr/bin/env perl
package sraXlib::Functions;
use strict;
use warnings;
use Time::HiRes qw(time);
use Benchmark;

sub check_dir {
	my $dir = shift;
	my $dir_pres='';
	unless(-d $dir){
		$dir_pres = 0;
	}else{
		$dir_pres = 1;
	}

	return ($dir_pres);
}

sub check_file {
	my $file = shift;
	my $f_pres='';
	unless(-f $file){
		$f_pres = 0;
	}else{
		$f_pres = 1;
	}

	return ($f_pres);
}

sub translate_sq {
	my $dna_sq = shift;
	no warnings "exiting";
	next if (length($dna_sq)<=3);

	my %dna_sq_by_fr;
	$dna_sq_by_fr{1} = substr($dna_sq, 0); 
	$dna_sq_by_fr{2} = substr($dna_sq, 1);
	$dna_sq_by_fr{3} = substr($dna_sq, 2);

	$dna_sq_by_fr{4} = revcmp($dna_sq_by_fr{1});
	$dna_sq_by_fr{5} = revcmp($dna_sq_by_fr{2});
	$dna_sq_by_fr{6} = revcmp($dna_sq_by_fr{3});

	my %num_stp_cdn;
	my %longest_dna_sub_sq;
	for my $fr(sort {$a <=> $b} keys %dna_sq_by_fr){
		my $len_dna_sq = length($dna_sq_by_fr{$fr});
		my $aa_sq = '';
		my $dna_sub_sq = '';
		for (my $pos = 0; $pos<=($len_dna_sq); $pos+=3) {
			my $codon = substr($dna_sq_by_fr{$fr}, $pos, 3);
			$dna_sub_sq .= $codon;
			my $aa = determine_aa($codon);
			$aa_sq .= $aa;
			if($aa =~/\*/){
				$num_stp_cdn{$fr}++;
				push(@{ $longest_dna_sub_sq{length($dna_sub_sq)} }, $dna_sub_sq);
				$aa_sq = '';
				$dna_sub_sq = '';
			}
		}
	}

	my $len_dna_sq_out = (sort {$a <=> $b} keys %longest_dna_sub_sq)[-1];
	my $dna_sq_out = $longest_dna_sub_sq{$len_dna_sq_out}[0];
	my $aa_sq_out = '';	

	for (my $pos = 0; $pos<=($len_dna_sq_out); $pos+=3) {
		my $codon = substr($dna_sq_out, $pos, 3);
		my $aa = determine_aa($codon);
		$aa_sq_out .= $aa;
	}

	return($dna_sq_out, $aa_sq_out);
}

sub get_aa_sq{
	my $dna_sq = shift;
	my $len_dna_sq = length($dna_sq);
	my $aa_sq = '';

	for (my $pos = 0; $pos<=($len_dna_sq); $pos+=3) {
		my $codon = substr($dna_sq, $pos, 3);
		my $aa = determine_aa($codon);
		$aa_sq .= $aa;
	}

	return($aa_sq);
}



sub determine_aa {
	my $codon = shift;
	$codon=lc($codon);
	my $aa='';

	if ( $codon =~ m/tt[tc]/ ) {
		$aa = 'F';
	} elsif ( $codon =~ m/tt[ag]|ct[agct]/ ) {
		$aa = 'L';
	} elsif ( $codon =~ m/at[tca]/ ) {
		$aa = 'I';
	} elsif ( $codon =~ m/atg/ ) {
		$aa = 'M';
	} elsif ( $codon =~ m/gt[tgac]/ ) {
		$aa = 'V';
	} elsif ( $codon =~ m/tc[tgac]|ag[tc]/ ) {
		$aa = 'S';
	} elsif ( $codon =~ m/cc[tgac]/ ) {
		$aa = 'P';
	} elsif ( $codon =~ m/ac[tgac]/ ) {
		$aa = 'T';
	} elsif ( $codon =~ m/gc[tgac]/ ) {
		$aa = 'A';
	} elsif ( $codon =~ m/ta[tc]/ ) {
		$aa = 'Y';
	} elsif ( $codon =~ m/ta[ag]|tga/ ) {
		$aa = '*';
	} elsif ( $codon =~ m/ca[tc]/ ) {
		$aa = 'H';
	} elsif ( $codon =~ m/ca[ag]/ ) {
		$aa = 'Q';
	} elsif ( $codon =~ m/aa[tc]/ ) {
		$aa = 'N';
	} elsif ( $codon =~ m/aa[ag]/ ) {
		$aa = 'K';
	} elsif ( $codon =~ m/ga[tc]/ ) {
		$aa = 'D';
	} elsif ( $codon =~ m/ga[ag]/ ) {
		$aa = 'E';
	} elsif ( $codon =~ m/tg[tc]/ ) {
		$aa = 'C';
	} elsif ( $codon =~ m/tgg/ ) {
		$aa = 'W';
	} elsif ( $codon =~ m/cg[tgac]|ag[ag]/ ) {
		$aa = 'R';
	} elsif ( $codon =~ m/gg[tgac]/ ) {
		$aa = 'G';
	}
	return($aa);
}


sub revcmp {
	my $dna_sq = shift;

	my $rvcp_dna_sq=reverse ($dna_sq);
	$rvcp_dna_sq =~ tr/AaCcTtGgMmRrYyKkVvHhDdBb/TtGgAaCcKkYyRrMmBbDdHhVv/;

	return $rvcp_dna_sq;

}

sub load_db_gn{
	my ($amr_db_dir,$amr_gn,$acc_id,$m_type) = @_;

	my ($out_hdr_aa,$out_sq_aa,$out_hdr_dna,$out_sq_dna);
	unless($m_type eq "rRNA_gene_variant"){
		($out_hdr_aa, $out_sq_aa) = load_amr_sq("$amr_db_dir/arg_aa.fa",$amr_gn,$acc_id);
		($out_hdr_dna, $out_sq_dna) = load_amr_sq("$amr_db_dir/arg_dna.fa",$amr_gn,$acc_id);
	}else{
		($out_hdr_dna, $out_sq_dna) = load_amr_sq("$amr_db_dir/arg_rna.fa",$amr_gn,$acc_id);
	}

	return ($out_hdr_aa,$out_sq_aa,$out_hdr_dna,$out_sq_dna);
}

sub load_amr_sq{
	my ($file,$amr_gn,$acc_id) = @_;

	my ($out_hdr, $out_sq)=("","");
	my %seq;
	my $str;
	open(INPUT,"$file") or die "Cannot open input fasta file: $!\n";
	while(<INPUT>){
		chomp;
		if(/^>/){
			($str = $_) =~ s/^>//;
		}else{
			s/\s+//g;
			$seq{$str} .= $_;
		}
	}
	close INPUT;

	foreach my $cnt (keys %seq){
		my @dat = split ('.@.', $cnt);
		if ($dat[1] eq $amr_gn && $dat[2] eq $acc_id){
			($out_hdr, $out_sq) = ($cnt, $seq{$cnt});
		}else{
			next;
		}
	}

	return ($out_hdr, $out_sq);
}

sub load_contig{
	my ($gnm_dir,$gnm,$contig) = @_;

	my %seq;
	my $str;
	open(INPUT,"$gnm_dir/$gnm") or die "Cannot open input fasta file: $!\n";
	while(<INPUT>){
		chomp;
		if(/^>/){
			($str = $_) =~ s/^>//;
			$str =~ s/\s+.*//;
		}else{
			s/\s+//g;
			$seq{$str} .= $_;
		}
	}
	close INPUT;

	my $out_cnt="";
	foreach my $cnt (keys %seq){
		$out_cnt=$seq{$contig}, unless (!$seq{$contig});
	}

	return ($out_cnt);
}

sub load_files{
	my ($fasta_dir, $ext) = @_;

	opendir IN, $fasta_dir or die $!;
	my @files = readdir IN;
	closedir IN or die $!;
	my @fasta_files;
	foreach my $ext (@$ext){
		push @fasta_files, grep /\.$ext$/, @files;
	}
	return \@fasta_files;
}

sub print_time{
	my $step = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	my $time_data = sprintf "Time: %02d:%02d hs | Date: %04d-%02d-%02d", $hour,$min, $year+1900,$mon+1,$mday;

	return ($time_data);
}

sub running_time {
	my $out_time =time();
	return ($out_time);
}

sub print_e{
	my ($opt,$val)=@_;
	my $msg = "\n[Error]: The '$opt' option does not recognize the given value '$val'.\n";
	$msg .= "Please, read the 'help' section.\n";
	$msg .= "\nSuspending the execution of 'sraX' and quitting now!\n";
	return($msg);
}

sub print_ne {
	my ($opt,$val)=@_;
	my $msg = "\nThe option '$opt' will be run under the following value: '$val'.\n";
	return($msg);
}

1;
