#!/usr/bin/env perl
package sraXlib::DB;
use strict;
use warnings;
use LWP::Simple;
use Data::Dumper;
use JSON;
use File::Slurp qw(edit_file read_file);
use sraXlib::Functions;

my $amr_dna		= "arg_dna.fa";
my $amr_rna             = "arg_rna.fa";
my $amr_aa		= "arg_aa.fa";
my $t_start_time	= sraXlib::Functions::running_time;
my $d_start_time 	= "";

my %rdc_size_dna;
my %rdc_size_rna;
my %rdc_size_aa;
my %sq_type;

sub get_publ_db {
	my ($d_out,$usr_or_not,$dbsearch) = @_;

	$d_start_time = sraXlib::Functions::print_time;
	print STDOUT "\nThe compilation process of the ARG DB started at:\t$d_start_time\n\n";

	my $start_time_db = sraXlib::Functions::running_time;

	my ($amr_db_fasta,$amr_db_fasta_tmp) = ("","");

	my $amr_db_fasta_dna = "$d_out/tmp/card_dna.fa";
	my $amr_db_fasta_rna = "$d_out/tmp/card_rna.fa";	
	my $amr_db_fasta_aa = "$d_out/tmp/card_aa.fa";

	open(FASTA_DNA,">$amr_db_fasta_dna") or die "Cannot open input fasta file: $!\n";
	open(FASTA_RNA,">$amr_db_fasta_rna") or die "Cannot open input fasta file: $!\n";
	open(FASTA_AA,">$amr_db_fasta_aa") or die "Cannot open input fasta file: $!\n";       

	my $ua   = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0, } );
	my $g_card = $ua->get("https://card.mcmaster.ca/download/0/broadstreet-v3.0.7.tar.gz");
	if (!$g_card->is_success){
		print "Failed to fetch data from 'CARD' AMR DB\n";
		print $g_card->status_line ."\n";
		print "Skipping 'CARD' AMR DB\n\n";
		no warnings "exiting";
		exit;
	}else{
		print "\tNucleotide sequence data from 'CARD' was successfully fetched\n";
		open my $fh, ">", "$d_out/tmp/tmpcard.tar.gz";
		print {$fh} $g_card->content;
	}

	system("tar xf $d_out/tmp/tmpcard.tar.gz ./card.json ./aro_categories_index.tsv ./aro_index.tsv");
	system("mv card.json $d_out/tmp/");
	system("mv aro_categories_index.tsv $d_out/tmp/");
	system("mv aro_index.tsv $d_out/tmp/");

	open(ARO_CAT,"$d_out/tmp/aro_categories_index.tsv") or die "Cannot open input 'aro_categories_index.tsv' file: $!\n";
	my %recov;
	my %aro_cat;
	while(<ARO_CAT>){
		chomp;
		my @data = split("\t", $_);
		$data[3] =~ s/ antibiotic//g;
		$data[3] =~ s/\;/\_/g;
		$data[3] =~ s/^([a-z])/\u$1/;
		$aro_cat{$data[0]} = $data[3];
	}
	close ARO_CAT;

	open(ARO_IDX,"$d_out/tmp/aro_index.tsv") or die "Cannot open input 'aro_index.tsv' file:$!\n";
	my %aro_idx;
	while(<ARO_IDX>){
		chomp;
		my @data = split("\t", $_);
		next if $data[0] eq '"ARO Accession"';
		$data[5] =~ s/"//g;
		$aro_idx{$data[5]} = $aro_cat{$data[6]};
	}
	close ARO_IDX;

	my $card = from_json(read_file("$d_out/tmp/card.json"), { latin1=>1 });
	my $decoded = decode_json(read_file("$d_out/tmp/card.json"));

	for my $data (values %$card) {
		next unless ref($data) eq 'HASH';

		my $amr_models = $data->{model_type};
		next unless(defined $amr_models);
		$amr_models =~s/\s+model//;
		$amr_models =~s/\s+meta-model//;
		my $aro_id  = $data->{ARO_id};
		my $gn_id =  $data->{ARO_name};
		my $nh = "";
		my $gn_def = $data->{ARO_description};
		$gn_def =~ s/^$gn_id is an\s+|^$gn_id is a\s+//gi;
		$gn_def =~ s/^$gn_id is the\s+//gi;
		$gn_def =~ s/^([a-z])/\u$1/;
		$gn_def =~ s/[^[:ascii:]]+//g;
		$gn_def =~ s/\,//g;
		$gn_def =~ s/\//_/g;
		$gn_def =~ s/\s+/_/g;
		if($amr_models eq "protein homolog"){
			my $amr_models_f = $amr_models;
			$amr_models_f =~ s/^\s+|\s+$//g;
			$amr_models_f =~ s/\s+/_/g;
			my $sq_pa =  $data->{model_sequences}{sequence} or next;
			for (keys %$sq_pa){
				$sq_pa = $sq_pa->{$_};
				my $dna_sq = $sq_pa->{dna_sequence} or next;
				my $aa_sq  = $sq_pa->{protein_sequence} or next;
				my $acc_id_pa = $aa_sq->{accession};
				my $ncbi = $sq_pa->{NCBI_taxonomy} or next;
				my $ncbi_tax_name = $ncbi->{NCBI_taxonomy_name};
				$ncbi_tax_name =~s/ /\.\./g;
				my $ncbi_tax_id = $ncbi->{NCBI_taxonomy_id};
				my $card_tax_id = $ncbi->{NCBI_taxonomy_cvterm_id};
				my $m_dat   = $aro_id."_".$card_tax_id."_".$ncbi_tax_name."_".$ncbi_tax_id; 
				my $gn_id_n = $gn_id;
				$gn_id_n =~ s/^\s+|\s+$//g;
				$gn_id_n =~ s/\s+/_/g;
				my $atb_class_n = $aro_idx{$gn_id};
				$atb_class_n =~ s/^\s+|\s+$//g;
				$atb_class_n =~ s/\s+/_/g;
				$nh = "card.@.$gn_id_n.@.$acc_id_pa.@.$gn_def.@.$amr_models_f.@.$atb_class_n.@.$m_dat";
				unless(exists $rdc_size_dna{$dna_sq->{sequence}}){
					$sq_type{$nh}{dna} = $dna_sq->{sequence};
					print FASTA_DNA ">$nh\n$dna_sq->{sequence}\n";
				}
				$rdc_size_dna{$dna_sq->{sequence}}++;
				unless(exists $rdc_size_aa{$aa_sq->{sequence}}){
					$sq_type{$nh}{aa} = $aa_sq->{sequence};
					print FASTA_AA ">$nh\n$aa_sq->{sequence}\n";
				}
				$rdc_size_aa{$aa_sq->{sequence}}++;
			}

		}elsif($amr_models eq "protein variant" || $amr_models eq "protein overexpression"){
			my $snps = $data->{model_param}{snp} or next;
			my $amr_models_f = $amr_models;
			$amr_models_f =~ s/^\s+|\s+$//g;
			$amr_models_f =~ s/\s+/_/g;
			my $snp_pos = $snps->{param_value} or next;
			my $snp_list = join("_", map { $snp_pos->{$_} } keys %$snp_pos);
			my $sq =  $data->{model_sequences}{sequence} or next;
			for (keys %$sq){
				$sq = $sq->{$_};
				my $dna_sq = $sq->{dna_sequence} or next;
				my $acc_id_dna = $dna_sq->{accession};
				my $aa_sq  = $sq->{protein_sequence} or next;
				my $acc_id = $aa_sq->{accession};
				my $ncbi = $sq->{NCBI_taxonomy} or next;
				my $ncbi_tax_name = $ncbi->{NCBI_taxonomy_name};
				$ncbi_tax_name =~s/ /\.\./g;	
				my $ncbi_tax_id = $ncbi->{NCBI_taxonomy_id};
				my $card_tax_id	= $ncbi->{NCBI_taxonomy_cvterm_id};
				my $m_dat   = $aro_id."_".$card_tax_id."_".$ncbi_tax_name."_".$ncbi_tax_id;
				my $gn_id_n = $data->{ARO_name};
				$gn_id_n =~ s/^\s+|\s+$//g;
				$gn_id_n =~ s/\s+/_/g;
				$gn_id_n =~ s/-/_/g;			
				my $atb_class_n = $aro_idx{$gn_id};
				$atb_class_n =~ s/^\s+|\s+$//g;
				$atb_class_n =~ s/\s+/_/g;
				$nh = "card.@.$gn_id_n.@.$acc_id.@.$gn_def.@.$amr_models_f.@.$snp_list.@.$m_dat";
				unless(exists $rdc_size_dna{$dna_sq->{sequence}}){
					$sq_type{$nh}{dna} = $dna_sq->{sequence};
					print FASTA_DNA ">$nh\n$dna_sq->{sequence}\n";
				}
				$rdc_size_dna{$dna_sq->{sequence}}++;
				unless(exists $rdc_size_aa{$aa_sq->{sequence}}){
					$sq_type{$nh}{aa} = $aa_sq->{sequence};
					print FASTA_AA ">$nh\n$aa_sq->{sequence}\n";
				}
				$rdc_size_aa{$aa_sq->{sequence}}++;
			}
		}elsif($amr_models eq "rRNA gene variant"){
			my $snps = $data->{model_param}{snp} or next;
			my $snp_pos = $snps->{param_value} or next;
			my $snp_list = join("_", map { $snp_pos->{$_} } keys %$snp_pos);
			my $amr_models_f = $amr_models;
			$amr_models_f =~ s/^\s+|\s+$//g;
			$amr_models_f =~ s/\s+/_/g;
			my $sq =  $data->{model_sequences}{sequence} or next;
			for (keys %$sq){
				$sq = $sq->{$_};
				my $dna_sq = $sq->{dna_sequence} or next;
				my $acc_id = $dna_sq->{accession};
				my $ncbi = $sq->{NCBI_taxonomy} or next;
				my $ncbi_tax_name = $ncbi->{NCBI_taxonomy_name};
				$ncbi_tax_name =~s/ /\.\./g;
				my $ncbi_tax_id = $ncbi->{NCBI_taxonomy_id};
				my $card_tax_id = $ncbi->{NCBI_taxonomy_cvterm_id};
				my $m_dat   = $aro_id."_".$card_tax_id."_".$ncbi_tax_name."_".$ncbi_tax_id;
				my $gn_id_n = $data->{ARO_name};
				$gn_id_n =~ s/^\s+|\s+$//g;
				$gn_id_n =~ s/\s+/_/g;
				$gn_id_n =~ s/-/_/g;			
				my $atb_class_n = $aro_idx{$gn_id};
				my @atb_class_n = split("_", $gn_id_n);
				$atb_class_n = $atb_class_n[-1];
				$nh = "card.@.$gn_id_n.@.$acc_id.@.$gn_def.@.$amr_models_f.@.$snp_list.@.$m_dat";
				unless(exists $rdc_size_dna{$dna_sq->{sequence}}){
					$sq_type{$nh}{rna} = $dna_sq->{sequence};
					print FASTA_DNA ">$nh\n$dna_sq->{sequence}\n";
					print FASTA_RNA ">$nh\n$dna_sq->{sequence}\n";
				}
				$rdc_size_dna{$dna_sq->{sequence}}++;
			}
		}
	}
	close FASTA_DNA;
	close FASTA_RNA;
	close FASTA_AA;

	print "\tTotal number of DNA sequences: ";
	system("grep '>' $amr_db_fasta_dna | wc -l");

	print "\tTotal number of RNA sequences: ";
	system("grep '>' $amr_db_fasta_rna | wc -l");


	print "\tProtein sequence data from 'CARD' was successfully fetched\n";
	print "\tTotal number of AA sequences: ";
	system("grep '>' $amr_db_fasta_aa | wc -l");

	my $stop_time_db = sraXlib::Functions::running_time;

	print STDOUT "\tThe collection of FASTA sequences from CARD took ";
	printf("%.2f ", $stop_time_db - $start_time_db);
	print STDOUT " wallclock secs\n\n";


	unless ($dbsearch !~m/ext|extensive/){
		($amr_db_fasta,$amr_db_fasta_tmp) = ("","");
		$amr_db_fasta_aa = "$d_out/tmp/argminer_aa.fa";
		my ($gn_id,$acc_id,$gn_def,$det_mod,$amr_class,$m_dat);
		my %add_pubdb;
		my $nh;
		my ($dna_t,$aa_t) = (0,0);

		$d_start_time = sraXlib::Functions::print_time;
		print STDOUT "\nThe compilation process of the ARGminer DB started at:\t$d_start_time\n\n";

		open(FASTA_AA,">$amr_db_fasta_aa") or die "Cannot open input fasta file: $!\n";       

		$ua   = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0, } );
		my $g_argminer = $ua->get("http://bench.cs.vt.edu/ftp/argminer/release/ARGminer-v1.1.1.A.fasta");
		if (!$g_argminer->is_success){
			print "Failed to fetch data from 'ARGminer' AMR DB\n";
			print $g_argminer->status_line ."\n";
			print "Skipping 'ARGminer' AMR DB\n\n";
			no warnings "exiting";
			exit;
		}else{
			open my $fh, ">", "$d_out/tmp/tmpargminer.fa";
			print {$fh} $g_argminer->content;
		}

		print "\tProtein sequence data from 'ARGminer' was successfully fetched\n";
		print "\tTotal number of AA sequences: ";
		system("grep '>' $d_out/tmp/tmpargminer.fa | wc -l");

		open(ARGminer,"$d_out/tmp/tmpargminer.fa") or die "Cannot open input fasta file:$!\n";
		while(<ARGminer>){
			chomp;
			if(/^>/){
				($nh = $_) =~ s/^>//;
				($acc_id,$amr_class,$gn_id,$gn_def) = split(/\|/, $nh);

				if($acc_id =~m/gi\:(\d+)\:(\w+)\:(.*):/g){
					$acc_id = $3;
				}

				($det_mod,$m_dat) = ("protein_homolog","Not_indicated"); 
				$gn_id  = "Not_indicated" unless $gn_id;
				my @gn_id = split(/ /, $gn_id);
				unless(scalar @gn_id == 1){
					$gn_id  =~ s/beta-lactamase//g;
					if(scalar @gn_id == 3){
						$gn_id = $gn_id[$#gn_id];
						$m_dat = "$gn_id[0] $gn_id[1]";
					}
				}

				$acc_id = "Not_indicated" unless $acc_id;
				$gn_def = "Not_indicated" unless $gn_def;
				$gn_def =~ s/^([a-z])/\u$1/;
				$det_mod= "Not_indicated" unless $det_mod;
				$amr_class = "Not_indicated" unless $amr_class;
				my @amr_class = split(/\;/, $amr_class);
				$amr_class = $amr_class[0];
				$amr_class =~ s/^([a-z])/\u$1/;

				$m_dat = "Not_indicated" unless $m_dat;
				$gn_id =~ s/^\s+|\s+$//g;
				$gn_id =~ s/\s+/_/g;
				$acc_id =~ s/^\s+|\s+$//g;
				$acc_id =~ s/\s+/_/g;
				$gn_def =~ s/^\s+|\s+$//g;
				$gn_def =~ s/\s+/_/g;
				$det_mod =~ s/^\s+|\s+$//g;
				$det_mod =~ s/\s+/_/g;
				$amr_class =~ s/^\s+|\s+$//g;
				$amr_class =~ s/\s+/_/g;
				$m_dat =~ s/^\s+|\s+$//g;
				$m_dat =~ s/\s+/_/g;
				$nh = "argminer.@.$gn_id.@.$acc_id.@.$gn_def.@.$det_mod.@.$amr_class.@.$m_dat";
			}else{
				s/\s+//g;
				$add_pubdb{$nh} .= $_;
			}
		}
		close ARGminer;

		foreach my $sq (keys %add_pubdb){
			unless(exists $rdc_size_aa{$add_pubdb{$sq}}){
				$aa_t++;
				$sq_type{$sq}{aa} = $add_pubdb{$sq};
				print FASTA_AA ">$sq\n$add_pubdb{$sq}\n";
			}
			$rdc_size_aa{$add_pubdb{$sq}}++;
		}
		unless($aa_t == 0){
			print "\tProtein sequence data from 'ARGminer' was successfully gathered\n";
			print "\tTotal number of AA sequences: $aa_t\n";
		}

		close FASTA_AA;

		$stop_time_db = sraXlib::Functions::running_time;

		print STDOUT "\tThe collection of FASTA sequences from ARGminer took ";
		printf("%.2f ", $stop_time_db - $start_time_db);
		print STDOUT " wallclock secs\n\n";
		($amr_db_fasta,$amr_db_fasta_tmp) = ("","");
		$amr_db_fasta_aa = "$d_out/tmp/bacmet_aa.fa";
		($gn_id,$acc_id,$gn_def,$det_mod,$amr_class,$m_dat,$nh,$dna_t,$aa_t) = ("","","","","","","",0,0);

		$d_start_time = sraXlib::Functions::print_time;
		print STDOUT "\nThe compilation process of the BacMet DB started at:\t$d_start_time\n\n";

		open(FASTA_AA,">$amr_db_fasta_aa") or die "Cannot open input fasta file: $!\n";       

		$ua   = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0, } );
		my $g_bacmet = $ua->get("http://bacmet.biomedicine.gu.se/download/BacMet2_EXP_database.fasta");
		if (!$g_bacmet->is_success){
			print "Failed to fetch data from 'BacMet' AMR DB\n";
			print $g_bacmet->status_line ."\n";
			print "Skipping 'BacMet' AMR DB\n\n";
			no warnings "exiting";
			exit;
		}else{
			open my $fh, ">", "$d_out/tmp/tmpbacmet.fa";
			print {$fh} $g_bacmet->content;
		}

		print "\tProtein sequence data from 'BacMet' was successfully fetched\n";
		print "\tTotal number of AA sequences: ";
		system("grep '>' $d_out/tmp/tmpbacmet.fa | wc -l");

		open(BacMet,"$d_out/tmp/tmpbacmet.fa") or die "Cannot open input fasta file:$!\n";
		while(<BacMet>){
			chomp;
			if(/^>/){
				($nh = $_) =~ s/^>//;
				my @dat = split(/\|/, $nh);
				($acc_id,$amr_class,$gn_id,$gn_def) = ($dat[3],"Metal-resistance",$dat[1],$dat[4]);
				($det_mod,$m_dat) = ("protein_homolog","Not_indicated"); 
				$gn_id  = "Not_indicated" unless $gn_id;
				$acc_id = "Not_indicated" unless $acc_id;
				$gn_def = "Not_indicated" unless $gn_def;
				if($gn_def=~m/^(.*)\s+OS=(.*)\s+GN=/g){
					$gn_def= $1;
					$m_dat = $2;
					my @gn_def = split(/ /, $gn_def);
					$gn_def=~s/$gn_def[0]//;
				}
				$det_mod= "Not_indicated" unless $det_mod;
				$amr_class = "Not_indicated" unless $amr_class;
				$m_dat = "Not_indicated" unless $m_dat;
				$gn_id =~ s/^\s+|\s+$//g;
				$gn_id =~ s/\s+/_/g;
				$acc_id =~ s/^\s+|\s+$//g;
				$acc_id =~ s/\s+/_/g;
				$gn_def =~ s/^\s+|\s+$//g;
				$gn_def =~ s/\s+/_/g;
				$det_mod =~ s/^\s+|\s+$//g;
				$det_mod =~ s/\s+/_/g;
				$amr_class =~ s/^\s+|\s+$//g;
				$amr_class =~ s/\s+/_/g;
				$m_dat =~ s/^\s+|\s+$//g;
				$m_dat =~ s/\s+/_/g;
				$nh = "bacmet.@.$gn_id.@.$acc_id.@.$gn_def.@.$det_mod.@.$amr_class.@.$m_dat";
			}else{
				s/\s+//g;
				$add_pubdb{$nh} .= $_;
			}
		}
		close BacMet;

		foreach my $sq (keys %add_pubdb){
			unless(exists $rdc_size_aa{$add_pubdb{$sq}}){
				$aa_t++;
				$sq_type{$sq}{aa} = $add_pubdb{$sq};
				print FASTA_AA ">$sq\n$add_pubdb{$sq}\n";
			}
			$rdc_size_aa{$add_pubdb{$sq}}++;
		}
		unless($aa_t == 0){
			print "\tProtein sequence data from 'BacMet' was successfully gathered\n";
			print "\tTotal number of AA sequences: $aa_t\n";
		}

		close FASTA_AA;

		$stop_time_db = sraXlib::Functions::running_time;

		print STDOUT "\tThe collection of FASTA sequences from BacMet took ";
		printf("%.2f ", $stop_time_db - $start_time_db);
		print STDOUT " wallclock secs\n\n";

	}
	unless ($usr_or_not eq "usq"){
		stop_download_amr_db($t_start_time, $d_out);
	}
}

sub get_user_db {
	my ($d_out,$user_db) = @_;
	my $start_time_user_db = sraXlib::Functions::running_time;
	my %add_usr;
	my $nh;
	open(FASTA,$user_db) or die "Cannot open input fasta file:$!\n";
	while(<FASTA>){
		chomp;
		if(/^>/){
			($nh = $_) =~ s/^>//;
			my ($gn_id,$acc_id,$gn_def,$det_mod,$amr_class,$m_dat) = split(/\|/, $nh);
			$gn_id  = "Not_indicated" unless $gn_id;
			$acc_id = "Not_indicated" unless $acc_id;
			$gn_def = "Not_indicated" unless $gn_def;
			$gn_id  = $gn_def unless $gn_def eq "Not_indicated";
			$det_mod= "protein_homolog" unless $det_mod;
			$amr_class = "Not_indicated" unless $amr_class;
			$m_dat = "Not_indicated" unless $m_dat;
			$gn_id =~ s/^\s+|\s+$//g;
			$gn_id =~ s/\s+/_/g;
			$acc_id =~ s/^\s+|\s+$//g;
			$acc_id =~ s/\s+/_/g;
			$gn_def =~ s/^\s+|\s+$//g;
			$gn_def =~ s/\s+/_/g;
			$det_mod =~ s/^\s+|\s+$//g;
			$det_mod =~ s/\s+/_/g;
			$amr_class =~ s/^\s+|\s+$//g;
			$amr_class =~ s/\s+/_/g;
			$m_dat =~ s/^\s+|\s+$//g;
			$m_dat =~ s/\s+/_/g;
			$nh = "user_db.@.$gn_id.@.$acc_id.@.$gn_def.@.$det_mod.@.$amr_class.@.$m_dat";
		}else{
			s/\s+//g; 
			$add_usr{$nh} .= $_;
		}
	}
	close FASTA;

	my ($dna_t,$aa_t) = (0,0);
	foreach my $sq (keys %add_usr){
		if ($add_usr{$sq} =~ m/D|E|F|P|Q/ig){
			unless(exists $rdc_size_aa{$add_usr{$sq}}){
				$aa_t++;
				$sq_type{$sq}{aa} = $add_usr{$sq};
			}
			$rdc_size_aa{$add_usr{$sq}}++;
		}else{
			unless(exists $rdc_size_dna{$add_usr{$sq}}){
				$dna_t++;
				$sq_type{$sq}{dna} = $add_usr{$sq};
			}
			$rdc_size_dna{$add_usr{$sq}}++;
			my $aa_sq = sraXlib::Functions::translate_sq($add_usr{$sq});
			$aa_sq =~ s/\*$//;
			unless(exists $rdc_size_aa{$aa_sq}){
				$aa_t++;
				$sq_type{$sq}{aa} = $aa_sq;
			}
			$rdc_size_aa{$aa_sq}++;
		}
	}
	unless($dna_t == 0){
		print "\tNucleotide sequence data from 'USER' was successfully gathered\n";
		print "\tTotal number of DNA sequences: $dna_t\n";
	}
	print "\tProtein sequence data from 'USER' was successfully gathered\n";
	print "\tTotal number of AA sequences: $aa_t\n";
	my $stop_time_user_db = sraXlib::Functions::running_time;
	print STDOUT "\tThe collection of FASTA sequences from USER (file: " .$user_db.") took ";
	printf("%.2f ", $stop_time_user_db - $start_time_user_db);
	print STDOUT " wallclock secs\n\n";
	stop_download_amr_db($t_start_time, $d_out);
}

sub stop_download_amr_db{
	my ($t_start_time_f, $d_out) = @_;

	$amr_dna = "$d_out/ARG_DB/$amr_dna";
	$amr_rna = "$d_out/ARG_DB/$amr_rna";
	$amr_aa  = "$d_out/ARG_DB/$amr_aa";

	open(ARG_DNA,">$amr_dna") || die "[ERROR]: Output file $amr_dna cannot be created: $!";
	open(ARG_RNA,">$amr_rna") || die "[ERROR]: Output file $amr_rna cannot be created: $!";
	open(ARG_AA,">$amr_aa") || die "[ERROR]: Output file $amr_aa cannot be created: $!";

	foreach my $sq (keys %sq_type){
		if (defined $sq_type{$sq}{dna} && defined $sq_type{$sq}{aa}){
			print ARG_DNA ">$sq\n$sq_type{$sq}{dna}\n";
			print ARG_AA ">$sq\n$sq_type{$sq}{aa}\n";
		}elsif(defined $sq_type{$sq}{aa}){
			print ARG_AA ">$sq\n$sq_type{$sq}{aa}\n";
		}elsif(defined $sq_type{$sq}{rna}){
			print ARG_RNA ">$sq\n$sq_type{$sq}{rna}\n";
		}else{
			next;
		}
	}

	close ARG_DNA;
	close ARG_RNA;
	close ARG_AA;

	my $t_stop_time_f = sraXlib::Functions::running_time;
	print STDOUT "\n\tThe collection of all selected sequence repositories took ";
	printf("%.2f ", $t_stop_time_f - $t_start_time_f);
	print STDOUT " wallclock secs\n\n";
	my $d_stop_time = sraXlib::Functions::print_time;
	print STDOUT "\nThe compilation process of the ARG DB finished at:\t$d_stop_time\n\n";
	print STDOUT "\nThe final ARG DB is composed of the following FASTA sequences:\n";
	print "\tTotal number of compiled DNA sequences: ";
	system("grep '>' $amr_dna | wc -l");
	print "\tTotal number of compiled RNA sequences: ";
	system("grep '>' $amr_rna | wc -l");
	print "\tTotal number of compiled AA sequences: ";
	system("grep '>' $amr_aa | wc -l");
}

1;
