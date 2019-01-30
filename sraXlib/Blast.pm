#!/usr/bin/env perl
package sraXlib::Blast;
use warnings;
use strict;
use Parallel::ForkManager;
use sraXlib::Functions;

my $pm = Parallel::ForkManager->new(100);
my $min_eval 	= "";
my $min_idty 	= "";
my $min_cvrg 	= "";
my $num_thrd	= "";
my $aa_abs_path = "";
my $dna_abs_path= "";
my $rna_abs_path= "";

sub set_prmt {
my ($d_gnm,$d_out,$bprog,$eval,$idty,$cvrg,$thrd) = @_;

$min_eval = $eval;
$min_idty = $idty;
$min_cvrg = $cvrg;
$num_thrd = $thrd;

	$aa_abs_path	= "$d_out/ARG_DB/arg_aa.fa";
	$dna_abs_path	= "$d_out/ARG_DB/arg_dna.fa";
	$rna_abs_path 	= "$d_out/ARG_DB/arg_rna.fa";

	my $f_out       = "$d_out/Analysis/Homology_Search/sraX_hs.tsv";

	if($bprog eq "dblastx"){
        system("diamond makedb --in $aa_abs_path -d $aa_abs_path --quiet");
	system("makeblastdb -in $rna_abs_path -dbtype nucl -hash_index -logfile '$rna_abs_path.log'");
	}elsif($bprog eq "blastx"){
        system("makeblastdb -in $aa_abs_path -dbtype prot -hash_index -logfile '$aa_abs_path.log'");
	system("makeblastdb -in $rna_abs_path -dbtype nucl -hash_index -logfile '$rna_abs_path.log'");
	}else{}

	my $f_pres = sraXlib::Functions::check_file($f_out);
	my $msg = "";
        	unless($f_pres == 1){
        	print STDERR "\nThe parsed data is written in the '$f_out' output file.\n";
        	print STDERR "Carrying out the execution of sraX!\n";
		$msg .= "\nThe parsed data is written in the '$f_out' output file.\n"; 
		$msg .= "Carrying out the execution of sraX!\n";
        	}else{
       		print STDERR "\n[Warn]: The homology search output file exists, implying that the script has already been run.\n";
		print STDERR "[Warn]: This file is going to be overwritten now.\n";
		$msg .= "\n[Warn]: The homology search output file exists, implying that the script has already been run.\n";
		$msg .= "[Warn]: This file is going to be overwritten now.\n";
        	system ("rm $f_out");
        	}

	open (OUT, ">$f_out") or die "\nThe output file can't be opened!\n";
	print OUT "Fasta_file\tContig_ID\tStart_query\tEnd_query\tAMR_gene\tCoverage\tStatus_hit\tNum_gaps\tCoverage_%\tIdentity_%\tATB_Drug_Class\tAccession_ID\tAMR_gene_definition\tAMR_detection_model\tMeta_data\n";

$msg .=	homology_seach($d_gnm,$d_out,$bprog);

return($msg);
}

sub homology_seach{
my ($d_gnm,$d_out,$bprog) = @_;

	my $t_start_time = sraXlib::Functions::running_time;
	my $d_start_time = sraXlib::Functions::print_time;
	print STDOUT "\nThe homology search process started at:\t$d_start_time\n\n";
	my $msg = "\nThe homology search process started at:\t$d_start_time\n\n";

	my $fasta = sraXlib::Functions::load_files($d_gnm, ["fasta", "fas", "fa"]);
	my $t_gnm = scalar @$fasta;
	print STDOUT "\tNumber of Genomes to analyze: $t_gnm\n";
	$msg .= "\tNumber of Genomes to analyze: $t_gnm\n";
        foreach my $fasta (@$fasta){
	my $pid = $pm->start and next;
	my $start_time_gnm = sraXlib::Functions::running_time;
	my $anlzd_fa = $fasta;
	my $bprog_out = "$d_out/Analysis/Homology_Search/Individual_Genomes/$anlzd_fa";
        $fasta = "$d_gnm/$fasta";

	print STDERR "\tThe genome $anlzd_fa is being analyzed\n";
	$msg .= "\tThe genome $anlzd_fa is being analyzed\n";

        if($bprog eq "dblastx"){
	system("diamond blastx --db '$aa_abs_path.dmnd' --query $fasta --out $bprog_out"."_aa.out --outfmt 6 qseqid sseqid gaps qcovhsp slen pident length mismatch gapopen qstart qend sstart send --top 50 --evalue $min_eval --id $min_idty --threads $num_thrd --more-sensitive --salltitles --sallseqid --quiet");
	system("blastn -db $rna_abs_path -query $fasta -out $bprog_out"."_rna.out -outfmt '6 qseqid sseqid gaps qcovs slen pident length mismatch gapopen qstart qend sstart send' -evalue $min_eval -num_threads $num_thrd -show_gis 2> $fasta.log");
	}elsif($bprog eq "blastx"){
	system("blastx -db $aa_abs_path -query $fasta -out $bprog_out"."_aa.out -outfmt '6 qseqid sseqid gaps qcovs slen pident length mismatch gapopen qstart qend sstart send' -evalue $min_eval -num_threads $num_thrd -show_gis 2> $fasta.log");
	system("blastn -db $rna_abs_path -query $fasta -out $bprog_out"."_rna.out -outfmt '6 qseqid sseqid gaps qcovs slen pident length mismatch gapopen qstart qend sstart send' -evalue $min_eval -num_threads $num_thrd -show_gis 2> $fasta.log");
        }else{}

	open(BLAST_AA,"$bprog_out"."_aa.out") || die "[WARN]: There are not homolog to protein AMR genes in the '$anlzd_fa' genome: $!\n";
  	open (GNM_AA, ">$bprog_out"."_aa.bparsd") or die "\nThe output file can't be opened; $!\n";
	while (<BLAST_AA>) {
    	chomp($_);
	my @data = split (/\t/, $_);
	my @hdr = split(/\.@\./, $data[1]);
	my ($gn_id,$acc_id,$gn,$model_type,$atb_class,$m_dat) = ($hdr[1],$hdr[2],$hdr[3],$hdr[4],$hdr[5]);
        unless(defined $hdr[6]){
        $m_dat = "Not_indicated";
        }else{
        $m_dat = $hdr[$#hdr];
        }
		if($model_type eq "protein_variant"){
		$atb_class = "Mutations on protein gene";
		}elsif($model_type eq "protein_overexpression"){
		$atb_class = "Mutations on protein gene (overexpression)";
		}
	my $cov = $data[11].'-'.$data[12].'/'. $data[4];
	my $gaps = $data[8].'/'.$data[2];
	my $covp = sprintf("%.2f", 100 * ($data[6]-$data[2]) / $data[4]);
  	my $gn_status='';
  	my $gn_length =0;
        if ($data[11]>$data[12]){
        $gn_length = ($data[4]-($data[11]-$data[12])-1);
        }else{
        $gn_length = ($data[4]-($data[12]-$data[11])-1);
        }
        if ($gn_length == 0 && $data[8] == 0){
        $gn_status="Full gene, no gaps";
        }elsif ($gn_length == 0 && $data[8] > 0){
        $gn_status="Full gene and internal gaps";
        }elsif ($gn_length > 0 && $data[8] == 0){
        $gn_status="Partial gene, no gaps";
        }elsif ($gn_length > 0 && $data[8] > 0){
        $gn_status="Partial gene and internal gaps";
        }else{
        $gn_status="Check_this_one";
        }
	next if ($covp<$min_cvrg);
	print GNM_AA "$anlzd_fa\t$data[0]\t$data[9]\t$data[10]\t$gn_id\t$cov\t$gn_status\t$gaps\t$covp\t$data[5]\t$atb_class\t$acc_id\t$gn\t$model_type\t$m_dat\n";
  	}
	close (BLAST_AA);
	close (GNM_AA);

	open(BLAST_RNA,"$bprog_out"."_rna.out") || die die "[WARN]: There are not homolog to rRNA AMR genes in the '$anlzd_fa' genome: $!\n";
  	open (GNM_RNA, ">$bprog_out"."_rna.bparsd") or die "\nThe output file can't be opened: $!\n";
	while (<BLAST_RNA>) {
    	chomp($_);
	my @data = split (/\t/, $_);
	my @hdr = split(/\.@\./, $data[1]);
        my ($gn_id,$acc_id,$gn,$model_type,$atb_class,$m_dat) = ($hdr[1],$hdr[2],$hdr[3],$hdr[4],$hdr[5]);
	unless(defined $hdr[6]){
	$m_dat = "Not_indicated";
	}else{
	$m_dat = $hdr[$#hdr];
	}
		if($gn_id =~ m/16S/g){
		$atb_class = "Mutations on rRNA gene (16S)";
		}elsif($gn_id =~ m/23S/g){
		$atb_class = "Mutations on rRNA gene (23S)";
                }else{
		$atb_class = "Mutations on rRNA gene";
		}
	my $cov = $data[11].'-'.$data[12].'/'. $data[4];
	my $gaps = $data[8].'/'.$data[2];
	my $covp = sprintf("%.2f", 100 * ($data[6]-$data[2]) / $data[4]);
  	my $gn_status='';
  	my $gn_length =0;
        if ($data[11]>$data[12]){
	$gn_length = ($data[4]-($data[11]-$data[12])-1);
        my $q_corr = $data[10];
        $data[10]  = $data[9];
        $data[9]   = $q_corr;
        }else{
        $gn_length = ($data[4]-($data[12]-$data[11])-1);
        }
        if ($gn_length == 0 && $data[8] == 0){
        $gn_status="Full gene, no gaps";
        }elsif ($gn_length == 0 && $data[8] > 0){
        $gn_status="Full gene and internal gaps";
        }elsif ($gn_length > 0 && $data[8] == 0){
        $gn_status="Partial gene, no gaps";
        }elsif ($gn_length > 0 && $data[8] > 0){
        $gn_status="Partial gene and internal gaps";
        }else{
        $gn_status="Check_this_one";
        }
	next if ($covp<$min_cvrg);
	print GNM_RNA "$anlzd_fa\t$data[0]\t$data[9]\t$data[10]\t$gn_id\t$cov\t$gn_status\t$gaps\t$covp\t$data[5]\t$atb_class\t$acc_id\t$gn\t$model_type\t$m_dat\n";
  	}
  	close BLAST_RNA;
	close GNM_RNA;

	my $stop_time_gnm = sraXlib::Functions::running_time;
	my $span_time_gnm = ($stop_time_gnm - $start_time_gnm);
	print STDOUT "\tThe homology search of AMR genes in the " . $anlzd_fa . " genome took: ";
	printf("%.2f ", $stop_time_gnm - $start_time_gnm);
	print STDOUT " wallclock secs\n";
	$msg .= "\tThe homology search of AMR genes in the " . $anlzd_fa . " genome took: $span_time_gnm wallclock secs\n";
	$pm->finish(0);
	}
	$pm->wait_all_children;

	my $f_gnm = sraXlib::Functions::load_files("$d_out/Analysis/Homology_Search/Individual_Genomes/", ["bparsd"]);
        foreach my $fd_gnm (@$f_gnm){
	open(F_GNM,"$d_out/Analysis/Homology_Search/Individual_Genomes/$fd_gnm") || die die "[ERROR]: The input file '$fd_gnm' cannot be opened: $!\n";
        	while (<F_GNM>) {
		chomp;
		print OUT "$_\n"
		}
	}
	close(OUT);

my $t_stop_time = sraXlib::Functions::running_time;
my $t_span_time = ($t_stop_time - $t_start_time);
my $d_stop_time = sraXlib::Functions::print_time;
print STDOUT "\n\tThe homology search of AMR genes in the complete dataset took ";
print STDOUT " wallclock secs\n\n";
print STDOUT "\nThe homology search process finished at:\t$d_stop_time\n\n";

$msg .= "\n\tThe homology search of AMR genes in the complete dataset took $t_span_time wallclock secs\n\n";
$msg .= "\nThe homology search process finished at:\t$d_stop_time\n\n";

return($msg);
}

1;
