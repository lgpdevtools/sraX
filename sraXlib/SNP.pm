#!/usr/bin/env perl
package sraXlib::SNP;
use strict;
use warnings;
use sraXlib::Functions;

sub sq_variants {
	my ($d_out, $msa_slctd) = @_;
	my $d_aa_path = "$d_out/Analysis/MSA/AA";
	my $d_dna_path = "$d_out/Analysis/MSA/DNA";
	my $m_type = "";

	my $t_start_time_snp = sraXlib::Functions::running_time;
	my $d_start_time_snp = sraXlib::Functions::print_time;
	print "\nThe SNP analysis started at:\t$d_start_time_snp\n\n";

	my $dna_sqs = sraXlib::Functions::load_files($d_dna_path, ["fna","fasta", "fas", "fa"]);
	print "\tThe DNA variant detection will be performed in: ", scalar @$dna_sqs, " genes.\n";
	foreach my $dna_sq (@$dna_sqs){
		$m_type = get_SNPs($d_dna_path, $dna_sq, "DNA", $msa_slctd);
		system("mv $d_dna_path/*_snps.tsv $d_out/Analysis/MSA/DNA/SNP/");
	}

	my $aa_sqs = sraXlib::Functions::load_files($d_aa_path, ["fna","fasta", "fas", "fa"]);
	print "\tThe AA variant detection will be performed in: ", scalar @$aa_sqs, " genes.\n";
	foreach my $aa_sq (@$aa_sqs){
		$m_type = get_SNPs($d_aa_path, $aa_sq, "AA", $msa_slctd);
		system("mv $d_aa_path/*_snps.tsv $d_out/Analysis/MSA/AA/SNP/");
	}

	my $t_stop_time_snp = sraXlib::Functions::running_time;
	print "\n\tThe SNP analysis took ";
	printf("%.2f ", $t_stop_time_snp - $t_start_time_snp);
	print " wallclock secs\n\n";
	my $d_stop_time_snp = sraXlib::Functions::print_time;
	print "\nThe SNP analysis finished at:\t$d_stop_time_snp\n\n";
}


sub get_SNPs{
	my ($abs_path,$sq_file,$sq_type,$msa_algth) = @_;
	my $m_type = "";
	my $m_data = "";

	my $locus = $sq_file;
	$locus =~s/\.fa.*//;

	my $start_time_gnm = sraXlib::Functions::running_time;
	my $msa = "$abs_path/$locus.aligned";

	my $hdr_ref = "";
	open(REF,"$abs_path/$sq_file") or die "Cannot open input fasta file:$!\n";
	while(<REF>){
		chomp;
		if(/^>/){
			next unless $_ =~ /\.@\./;
			($hdr_ref = $_) =~ s/^>//;
		}else{
			next;
		}
	}
	close REF;

	if($msa_algth eq "muscle"){
		system("muscle -in $abs_path/$sq_file -out $msa -maxiters 1 -diags -sv -distance1 kbit20_3 -quiet");
		system("mv $msa $abs_path/$sq_file");
	}elsif($msa_algth eq "clustalo"){
		unless($sq_type eq 'DNA'){$sq_type='Protein';}
		system("clustalo --in $abs_path/$sq_file --infmt=fa --out $msa --outfmt=fa --seqtype=$sq_type --threads=6 --force ");
		system("mv $msa $abs_path/$sq_file");
	}elsif($msa_algth eq "prank"){
		system("prank -d=$abs_path/$sq_file -o=$msa -f=fasta -quiet");
		system("mv $msa $abs_path/$sq_file");
	}elsif($msa_algth eq "mafft"){
		system("mafft --maxiterate 1000 --globalpair --thread 6 --quiet $abs_path/$sq_file > $msa");
		system("mv $msa $abs_path/$sq_file");
	}else{
		die "[ERROR] The selected MSA algorithm is not currently employed by sraX";
	}

	open (OUT, ">$abs_path/$locus"."_snps.tsv") or die "The output file can not be created: $!\n";

	my %seq;
	my $hdr;

	my $sq_ref_idx = "";
	my $sq_num = 0;
	my @sq_num;
	open(INPUT,"$abs_path/$sq_file") or die "Cannot open input fasta file:$!\n";
	while(<INPUT>){
		chomp;
		if(/^>/){
			($hdr = $_) =~ s/^>//;
			if($hdr =~ /\.@\./){
				$sq_ref_idx = $sq_num;
				$hdr = $hdr_ref;
				my @dat = split (/\.@\./, $hdr);
				$m_type = $dat[4];
				$m_data = $dat[$#dat];
			}
			$sq_num[$sq_num] = $hdr;
			$sq_num++;
		}else{
			s/\s+//g;
			my $text=uc($_);
			$seq{$hdr}.=$text;
		}
	}
	close INPUT;

	return if $sq_ref_idx eq "";
	my @amr_sq = split(//,$seq{$sq_num[$sq_ref_idx]});

	my $snps = 0;
	my @snps;
	my @uniq;
	foreach my $gnm (keys %seq){
		my @gnm_sq=split(//,$seq{$gnm});
		for(my $i=0;$i<=$#amr_sq;$i++){
			if(($gnm_sq[$i] ne $amr_sq[$i]) && (!$uniq[$i])){
				next if ($gnm_sq[$i] eq '-' || $amr_sq[$i] eq '-');
				push (@snps, $i);
				$snps++;
				$uniq[$i]++;
			}
		}
	}

	@snps = sort ( {$a <=> $b} @snps);

	my %gnm;
	foreach(@snps){
		my $snp_pos = ($_+1);
		foreach my $gnm (keys %seq){
			my $aa = substr($seq{$gnm},$_,1);
			$gnm{$gnm}{$snp_pos} = $aa;
		}
	}

	my ($db_id,$gn_id,$acc_id,$gn_def,$det_model,$snp_res) = split(/\.@\./, $sq_num[$sq_ref_idx]);
	my %snp_all;
	my %uniq_3;
	foreach my $gnm (sort { lc $a cmp lc $b } keys %gnm){
		foreach my $snp_pos (sort { $a <=> $b } keys %{ $gnm{$gnm} }){
			unless(exists $uniq_3{$snp_pos}{$gnm{$gnm}{$snp_pos}}){
				push(@{ $snp_all{$snp_pos} }, $gnm{$gnm}{$snp_pos});
			}
			$uniq_3{$snp_pos}{$gnm{$gnm}{$snp_pos}}++;
		}
	}

	my $snp_total = 0;
	foreach my $snp_pos (sort { $a <=> $b } keys %snp_all){
		$snp_total += (scalar @{ $snp_all{$snp_pos} } - 1); 
	}

	print OUT "Summary of SNP data:\n";
	print OUT "Total number of genomes\t". ($sq_num-1). "\n";
	print OUT "Total number of SNPs\t". $snp_total . "\n";
	print OUT "MSA length\t". length($seq{$sq_num[$sq_ref_idx]}). "\n";
	print OUT "SNP density (#_SNPs/MSA_length)\t". sprintf( "%.3f", ($snp_total/length($seq{$sq_num[$sq_ref_idx]})) ). "\n\n";

	my %snp_res_pos;
	if($snp_res=~m/(\w)(\d+)(\w)/){
		my @snp_res = split(/\_/, $snp_res);
		my @snp_res_pos;
		foreach(@snp_res){
			my ($ref,$pos,$alt) = $_ =~m/(\w)(\d+)(\w)/g;  
			push (@snp_res_pos, $pos);
			$snp_res_pos{$pos}++;
		}
		my @idx = sort { $snp_res_pos[$a] <=> $snp_res_pos[$b] } 0 .. $#snp_res_pos;
		@snp_res_pos = @snp_res_pos[@idx];
		@snp_res = @snp_res[@idx];

		print OUT "SNPs conferring antibiotic resistance:\n";
		print OUT "Reference_Gene_ID\tAMR_DB\tAccession_ID\tSequence_position\t$sq_type"."_Ref\t$sq_type"."_Alt\tConfirmation_$sq_type"."_Alt\tGenome_ID_$sq_type"."_Alt\tNo._of_genomes_in_MSA\t%_of_genomes_in_MSA\n";

		my %snp_val;
		foreach(@snp_res){
			my ($ref,$pos,$alt) = $_ =~m/(\w)(\d+)(\w)/g;
			my $pos_orig = $pos;
			my $sub_ref_sq = substr($seq{$sq_num[$sq_ref_idx]},0,$pos);
			my $pos_corr = $sub_ref_sq =~ tr/-//;
			$pos = ($pos+$pos_corr);

			unless($pos_corr == 0){$pos_orig = $pos_orig." (gap introd.; MSA pos. : $pos)";}

			print OUT "$gn_id\t$db_id\t$acc_id\t$pos_orig\t$ref\t$alt\t";

			foreach my $gnm (sort { lc $a cmp lc $b } keys %seq){
				next if ($gnm eq $sq_num[0]);
				foreach my $snp_pos (sort { $a <=> $b } keys %{ $gnm{$gnm} }){
					if($snp_pos == $pos && $gnm{$gnm}{$snp_pos} eq $alt){
						push (@{ $snp_val{$pos}{$alt}{hit} }, $gnm);
					}elsif($snp_pos == $pos && $gnm{$gnm}{$snp_pos} ne $ref && $gnm{$gnm}{$snp_pos} ne $alt ){
						push (@{ $snp_val{$pos}{$alt}{new_var} }, $gnm);
					}else{
					}
				}
			}

			if(exists $snp_val{$pos}{$alt}{hit} && !exists $snp_val{$pos}{$alt}{new_var}){
				print OUT "Yes\t";
				for (0..$#{ $snp_val{$pos}{$alt}{hit} }){
					unless($snp_val{$pos}{$alt}{hit}[$_] eq $snp_val{$pos}{$alt}{hit}[-1]){
						print OUT "$snp_val{$pos}{$alt}{hit}[$_]; ";
					}else{
						print OUT "$snp_val{$pos}{$alt}{hit}[$_]\t".(scalar @{ $snp_val{$pos}{$alt}{hit} })."\t";
						print OUT  sprintf( "%.2f", ( (scalar @{ $snp_val{$pos}{$alt}{hit} }/($sq_num-1))*100 ) ) . "\n";
					}
				}
			}elsif(exists $snp_val{$pos}{$alt}{new_var} && exists $snp_val{$pos}{$alt}{hit}){
				print OUT "Yes\t";
				for (0..$#{ $snp_val{$pos}{$alt}{hit} }){
					unless($snp_val{$pos}{$alt}{hit}[$_] eq $snp_val{$pos}{$alt}{hit}[-1]){
						print OUT "$snp_val{$pos}{$alt}{hit}[$_]; ";
					}else{
						print OUT "$snp_val{$pos}{$alt}{hit}[$_]\t".(scalar @{ $snp_val{$pos}{$alt}{hit} })."\t";
						print OUT  sprintf( "%.2f", ( (scalar @{ $snp_val{$pos}{$alt}{hit} }/($sq_num-1))*100 ) ) . "\n";
					}
				}
				my %snp_var_gnm;
				my %snp_var_data;
				my %uniq;
				for (0..$#{ $snp_val{$pos}{$alt}{new_var} }){
					if($ref ne $gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos}){
						unless(exists $uniq{$gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos}}){
							$snp_var_data{$gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos}} = "$gn_id\t$db_id\t$acc_id\t$pos_orig\t$ref\t$alt\tSame_Position_New_Variant ($ref$pos$gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos})";
						}
						$uniq{$gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos}}++;
						push (@{ $snp_var_gnm{ $gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos} } }, $snp_val{$pos}{$alt}{new_var}[$_]);

					}else{
					}
				}

				foreach my $new_var (keys %snp_var_gnm){
					print OUT "$snp_var_data{$new_var}\t";
					for my $gnm (0..$#{ $snp_var_gnm{$new_var} }){
						unless($snp_var_gnm{$new_var}[$gnm] eq $snp_var_gnm{$new_var}[-1]){
							print OUT "$snp_var_gnm{$new_var}[$gnm]; ";
						}else{
							print OUT "$snp_var_gnm{$new_var}[$gnm]\t".(scalar @{ $snp_var_gnm{$new_var} })."\t";
							print OUT  sprintf( "%.2f", ( (scalar @{ $snp_var_gnm{$new_var} }/($sq_num-1))*100 ) ) . "\n";
						}
					}
				}
			}elsif(exists $snp_val{$pos}{$alt}{new_var} && !exists $snp_val{$pos}{$alt}{hit}){
				my %snp_var_gnm;
				my %snp_var_data;
				my %uniq;
				for (0..$#{ $snp_val{$pos}{$alt}{new_var} }){
					if($ref ne $gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos}){
						unless(exists $uniq{$gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos}}){
							$snp_var_data{$gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos}} = "Same_Position_New_Variant ($ref$pos$gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos})";
						}
						$uniq{$gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos}}++;
						push (@{ $snp_var_gnm{ $gnm{$snp_val{$pos}{$alt}{new_var}[$_]}{$pos} } }, $snp_val{$pos}{$alt}{new_var}[$_]);
					}else{
					}
				}

				foreach my $new_var (keys %snp_var_gnm){
					print OUT "$snp_var_data{$new_var}\t";
					for my $gnm (0..$#{ $snp_var_gnm{$new_var} }){
						unless($snp_var_gnm{$new_var}[$gnm] eq $snp_var_gnm{$new_var}[-1]){
							print OUT "$snp_var_gnm{$new_var}[$gnm]; ";
						}else{
							print OUT "$snp_var_gnm{$new_var}[$gnm]\t".(scalar @{ $snp_var_gnm{$new_var} })."\t";
							print OUT  sprintf( "%.2f", ( (scalar @{ $snp_var_gnm{$new_var} }/($sq_num-1))*100 ) ) . "\n";
						}
					}
				}
			}else{
				print OUT "No\t---\t0.00\t0.00\n";
			}
		}
		print OUT "\n\n";
	}

	print OUT "Other SNPs:\n";
	print OUT "Reference_Gene_ID\tAMR_DB\tAccession_ID\tSequence_position\t$sq_type"."_Ref\t$sq_type"."_Alt\tConfirmation_$sq_type"."_Alt\tGenome_ID_$sq_type"."_Alt\tNo._of_genomes_in_MSA\t%_of_genomes_in_MSA\n";

	my %snp_other;
	my %uniq_2;
	foreach my $gnm (sort { lc $a cmp lc $b } keys %gnm){
		foreach my $snp_pos (sort { $a <=> $b } keys %{ $gnm{$gnm} }){
			unless(exists $uniq_2{$snp_pos}{$gnm{$gnm}{$snp_pos}}){
				push(@{ $snp_other{$snp_pos} }, $gnm{$gnm}{$snp_pos});
			}
			$uniq_2{$snp_pos}{$gnm{$gnm}{$snp_pos}}++;
		}
	}

	foreach my $snp_pos (sort { $a <=> $b } keys %snp_other){
		for my $aa (0..$#{ $snp_other{$snp_pos} }){
			my @gnm_hits;
			my $gnm_hits = "";
			my $gnm_hits_num = 0;
			foreach my $gnm (sort { lc $a cmp lc $b } keys %gnm){
				next unless($gnm ne $sq_num[$sq_ref_idx]);
				next unless($gnm{$gnm}{$snp_pos} eq $snp_other{$snp_pos}[$aa]);
				$gnm_hits[$gnm_hits_num] = $gnm;
				$gnm_hits_num++;
			}
			foreach my $gnm (@gnm_hits){
				unless($gnm eq $gnm_hits[-1]){
					$gnm_hits .= "$gnm; ";
				}else{
					$gnm_hits .= "$gnm";
				}
			}
			next if (exists $snp_res_pos{$snp_pos});
			next if ($gnm{$sq_num[$sq_ref_idx]}{$snp_pos} eq $snp_other{$snp_pos}[$aa]);
			print OUT "$gn_id\t$db_id\t$acc_id\t$snp_pos\t$gnm{$sq_num[$sq_ref_idx]}{$snp_pos}\t$snp_other{$snp_pos}[$aa]\t---\t$gnm_hits\t$gnm_hits_num\t";
			print OUT sprintf( "%.2f", ( ( $gnm_hits_num/($sq_num-1) )*100  ) ) . "\n";
		}
	}
	print OUT "\n\n";
	print OUT "Genomes vs polymorphic columns:\n";
	print OUT "Genome_ID\t";
	foreach(@snps){
		my $snp_pos = ($_+1);
		unless($_ eq $snps[$#snps]){
			print OUT "$snp_pos\t";
		}else{
			print OUT "$snp_pos\n";
		}
	}
	print OUT $gn_id."_".$acc_id."\t";

	foreach my $snp_pos (sort { $a <=> $b } keys %{ $gnm{$sq_num[$sq_ref_idx]} }){
		unless($snp_pos eq ($snps[$#snps]+1)){
			print OUT "$gnm{$sq_num[$sq_ref_idx]}{$snp_pos}\t";
		}else{
			print OUT "$gnm{$sq_num[$sq_ref_idx]}{$snp_pos}\n";
		}
	}

	foreach my $gnm (sort { lc $a cmp lc $b } keys %seq){
		next if ($gnm eq $sq_num[$sq_ref_idx]);
		print OUT "$gnm\t";
		foreach my $snp_pos (sort { $a <=> $b } keys %{ $gnm{$gnm} }){
			unless($snp_pos eq ($snps[$#snps]+1)){
				print OUT "$gnm{$gnm}{$snp_pos}\t";
			}else{
				print OUT "$gnm{$gnm}{$snp_pos}\n";
			}
		}
	}

	close OUT;


	my %maf_sort;
	my $maf = 0;
	my %maf;	
	foreach my $gnm (keys %seq){
		next if ($gnm =~ /\.@\./);
		my @gnm_sq=split(//,$seq{$gnm});
		for(my $pos=0; $pos<@gnm_sq; $pos++) {
			my $res = $gnm_sq[$pos];
			$maf = $maf_sort{$pos}{$res}++;
			$maf{$pos}{$maf} = $res;
		}
	}

	my %maf_nt;
	foreach my $pos (sort {$a <=> $b} keys %maf){
		foreach my $maf (sort {$b <=> $a} keys %{ $maf{$pos} }){
			$maf_nt{$pos} = $maf{$pos}{$maf};
		}
	}

	unless($det_model eq 'protein_homolog'){
		my @locus = split(/\_/, $gn_id);
		if(($det_model eq 'protein_overexpression' || $det_model eq 'protein_variant') && scalar @locus <= 3){
		}else{
			$gn_id = $locus[2];
		}
	}
	$gn_def =~s/\_/ /g;
	$det_model =~s/\_/ /g;

	my ($aro_id,$card_tax_id,$ncbi_tax_name,$ncbi_tax_id);
	my @mdat = split(/\_/, $m_data);
	if($mdat[0] =~ m/^\d+$/ && $mdat[1] =~ m/^\d+$/){
		($aro_id,$card_tax_id,$ncbi_tax_name,$ncbi_tax_id) = ($mdat[0],$mdat[1],$mdat[2],$mdat[3]);
		if(defined $ncbi_tax_name){
			$ncbi_tax_name =~s/\.\./ /g;
		}
	}else{
		$ncbi_tax_name = $m_data;
		($aro_id,$card_tax_id,$ncbi_tax_id) = ("Not_indicated", "Not_indicated","Not_indicated");
	}

	my $html = "$abs_path/SNP/$locus.html";
	open MSA_HTML, ">$html" or die "Can't open $html: $!";
	print MSA_HTML "<html>\n<head>\n</head>\n<body>\n\n";

	unless($aro_id eq "Not_indicated"){
		print MSA_HTML "<H1 align=center><u><span style=background-color:#a2b5cd;color:#000000;><a href=https://card.mcmaster.ca/ontology/$aro_id target='_blank'>$gn_id</a></span></u></H1>\n\n";
	}else{
		print MSA_HTML "<H1 align=center><u><span style=background-color:#a2b5cd;color:#000000;>$gn_id</span></u></H1>\n\n";
	}

	print MSA_HTML "<table border=0><tr><td></td>\n";
	print MSA_HTML "<table border=0><tr><td></td>\n";
	print MSA_HTML "<table border=0><tr><td bgcolor=#DEDEDE><b>Definition:</td><td>$gn_def</td></tr>\n";
	print MSA_HTML "<table border=0><tr><td></td>\n";
	print MSA_HTML "<table border=0><tr><td></td>\n";

	unless($gn_def eq "Not indicated"){
		print MSA_HTML "<table border=0><tr><td bgcolor=#DEDEDE><b>Reference organism:</td><td><i>$ncbi_tax_name <i></td><td>[<span color:#000000;>";
		print MSA_HTML "<a href=https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$ncbi_tax_id target='_blank'>NCBI</a></span>";
		print MSA_HTML ", <span color:#000000;><a href=https://card.mcmaster.ca/ontology/$card_tax_id target='_blank'>CARD</a></span>]</tr>\n";
	}else{
		print MSA_HTML "<table border=0><tr><td bgcolor=#DEDEDE><b>Reference organism:</td><td>Not indicated</td>";
	}

	print MSA_HTML "<table border=0><tr><td></td>\n";
	print MSA_HTML "<table border=0><tr><td></td>\n";
	print MSA_HTML "<table id='summary_snp'><tbody><tr bgcolor=#DEDEDE><td style='text-align:center' colspan=2><b>Summary Data</b></td>";
	print MSA_HTML "<tr bgcolor=#DEDEDE><td align=center><b>Parameter<b></td><td align=center><b>Value<sub>(n)</sub><b></td>";
	print MSA_HTML "<tr><td>Total number of genomes</td><td align=center>$sq_num</td></tr>";
	print MSA_HTML "<tr><td>MSA length</td><td align=center>".length($seq{$sq_num[$sq_ref_idx]})."</td></tr>";
	print MSA_HTML "<tr><td>Total number of SNPs</td><td align=center>$snp_total</td></tr>";
	print MSA_HTML "<tr><td>SNP density (# SNPs/MSA length)</td><td align=center>".sprintf( "%.3f", ($snp_total/length($seq{$sq_num[$sq_ref_idx]})) )."</td></tr>";
	print MSA_HTML "<table border=0><tr><td></td>\n";
	print MSA_HTML "<table border=0><tr><td></td>\n";
	print MSA_HTML "<table border=0><tr><td></td>\n";
	print MSA_HTML "<table border=0><tr><td></td>\n";

	if ( ($sq_type eq 'DNA' && $m_type eq 'rRNA_gene_variant') || ($sq_type eq 'AA' && $m_type ne 'protein_homolog') ){
		my %snp_val_f;
		if($snp_res=~m/(\w)(\d+)(\w)/){
			$snp_res =~s/\s+//g;
			my @snp_res = split(/\_/, $snp_res);
			print MSA_HTML "<table id='amr_snp'><tr bgcolor=#DEDEDE><td style='text-align:center' colspan=5><b>SNPs conferring antibiotic resistance</b></td>";
			print MSA_HTML "<tr style='text-align:center' bgcolor=#DEDEDE><td><b>Reference gene<b></td><td><b>Seq. pos.<b></td><td><b>Ref_base<b></td><td><b>Alt_base<b></td><td><b>Confirmation SNP?<b></td>";
			my @snp_res_pos;
			foreach(@snp_res){
				my ($ref,$pos,$alt) = $_ =~m/(\w)(\d+)(\w)/g;
				push (@snp_res_pos, $pos);
				$snp_res_pos{$pos}++;
			}
			my @idx = sort { $snp_res_pos[$a] <=> $snp_res_pos[$b] } 0 .. $#snp_res_pos;
			@snp_res_pos = @snp_res_pos[@idx];
			@snp_res = @snp_res[@idx];
			my %snp_val;
			foreach(@snp_res){
				my ($ref,$pos,$alt) = $_ =~m/(\w)(\d+)(\w)/g;
				$alt =~s/U/T/ig;
				my $pos_orig = $pos;
				my $sub_ref_sq = substr($seq{$sq_num[$sq_ref_idx]},0,$pos);
				my $pos_corr = $sub_ref_sq =~ tr/-//;
				$pos = ($pos+$pos_corr);
				unless($pos_corr == 0){$pos_orig = $pos_orig." (gap introd.; MSA pos. : $pos)";}
				foreach my $gnm (sort { lc $a cmp lc $b } keys %seq){
					next if ($gnm eq $sq_num[0]);
					foreach my $snp_pos (sort { $a <=> $b } keys %{ $gnm{$gnm} }){
						if($snp_pos == $pos && $gnm{$gnm}{$snp_pos} eq $alt){
							push (@{ $snp_val{$pos}{$alt}{hit} }, $gnm);
						}else{
						}
					}
				}
				my $new_var = "";
				foreach my $gnm (sort { lc $a cmp lc $b } keys %seq){
					next if ($gnm eq $sq_num[0]);
					foreach my $snp_pos (sort { $a <=> $b } keys %{ $gnm{$gnm} }){
						if($snp_pos == $pos && $gnm{$gnm}{$snp_pos} eq $alt){
							$snp_val{$pos}{$alt}{hit}++
						}elsif($snp_pos == $pos && $gnm{$gnm}{$snp_pos} ne $ref && $gnm{$gnm}{$snp_pos} ne $alt ){
							$new_var = $gnm{$gnm}{$snp_pos};
							$snp_val{$pos}{$alt}{new_var}++;
						}else{
						}
					}
				}

				if($snp_val{$pos}{$alt}{hit}){
					print MSA_HTML "<tr><tr style='text-align:center'><td>$gn_id<td>$pos_orig<td>$ref<td>$alt<td><b><font color=#CC0000 size=3>Yes</font></b></td></tr>";
					$snp_val_f{$pos}{val}++;
				}elsif($snp_val{$pos}{$alt}{new_var}){
					print MSA_HTML "<tr><tr style='text-align:center'><td>$gn_id<td>$pos_orig<td>$ref<td>$alt<td><b><font color=#CC0000 size=2>SNP variant ($ref$pos$new_var)</font></b></td></tr>";
					$snp_val_f{$pos}{val}++;
				}else{
					print MSA_HTML "<tr><tr style='text-align:center'><td>$gn_id<td>$pos_orig<td>$ref<td>$alt<td><b><font color=#2F079E size=3>No</font></b></td></tr>";
					$snp_val_f{$pos}{nval}++;
				}
			}
		}

		print MSA_HTML "<table border=0><tr><td></td>\n";
		print MSA_HTML "<table border=0><tr><td></td>\n";
		print MSA_HTML "<table border=0><tr><td></td>\n";
		print MSA_HTML "<table border=0><tr><td></td>\n";

		my %gap;
		foreach my $gnm (keys %seq){
			my @gnm_sq=split(//,$seq{$gnm});
			for(my $pos=0; $pos<@gnm_sq; $pos++) {
				my $res = $gnm_sq[$pos];
				if($res eq '-'){
					$gap{$pos}++;
				}
			}
		}


		print MSA_HTML "<tr>\n";
		unless($acc_id=~m/sraxID/){
			print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2><span style='background:#F2671D;'>$ncbi_tax_name ($acc_id)</span></font></b></td>\n";
		}else{
			print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2><span style='background:#F2671D;'>$gn_id</span></font></b></td>\n";	
		}

		my @gnm_sq=split(//,$seq{$sq_num[$sq_ref_idx]});
		for(my $pos=0; $pos<@gnm_sq; $pos++) {
			my $res = $gnm_sq[$pos];
			my $maf_nt = $maf_nt{$pos};
			if($gap{$pos} && $res eq '-'){
				print MSA_HTML "<td width=5><b><font face='Courier New' color='#30CEF2' size=2>$res</font></b></td>\n";
			}elsif($gnm{$sq_num[$sq_ref_idx]}{$pos+1} && $snp_other{$pos+1} && !$snp_val_f{$pos+1}{val} && !$snp_val_f{$pos+1}{nval} && $res ne '-'){
				if($res eq $maf_nt){
					print MSA_HTML "<td width=5><b><font face='Courier New' color='#A51586' size=2><span style='background: #15A534;'>$res</span></font></b></td>\n";
				}else{
					print MSA_HTML "<td width=5><b><font face='Courier New' color='white' size=2><span style='background: #15A534;'>$res</span></font></b></td>\n";
				}
			}elsif($snp_val_f{$pos+1}{nval}){
				if($res eq $maf_nt){
					print MSA_HTML "<td width=5><b><font face='Courier New' color='#769E07' size=2><span style='background: #2F079E;'>$res</span></font></b></td>\n";
				}else{
					print MSA_HTML "<td width=5><b><font face='Courier New' color='white' size=2><span style='background: #2F079E;'>$res</span></font></b></td>\n";
				}
			}elsif($gnm{$sq_num[$sq_ref_idx]}{$pos+1} && $snp_val_f{$pos+1}{val}){
				if($res eq $maf_nt){
					print MSA_HTML "<td width=5><b><font face='Courier New' color='#00cccc' size=2><span style='background: #CC0000;'>$res</span></font></b></td>\n";
				}else{
					print MSA_HTML "<td width=5><b><font face='Courier New' color='white' size=2><span style='background: #CC0000;'>$res</span></font></b></td>\n";
				}	
			}else{
				print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2>$res</font></b></td>\n";
			}
		}
		print MSA_HTML "</tr>\n\n";

		foreach my $gnm (keys %seq){
			next if ($gnm =~ /\.@\./);
			my @sq_anlz = split ('.fa', $gnm);
			print MSA_HTML "<tr>\n";
			print MSA_HTML "<td><b><font face='Courier New' color='black' size=2>", $sq_anlz[0], "</font></b></td>\n";
			my @gnm_sq=split(//,$seq{$gnm});
			for(my $pos=0; $pos<@gnm_sq; $pos++) {
				my $res = $gnm_sq[$pos];
				my $maf_nt = $maf_nt{$pos};
				if($gap{$pos} && $res eq '-'){
					print MSA_HTML "<td width=5><b><font face='Courier New' color='#30CEF2' size=2>$res</font></b></td>\n";
				}elsif($gnm{$gnm}{$pos+1} && $snp_other{$pos+1} && !$snp_val_f{$pos+1}{val} && !$snp_val_f{$pos+1}{nval} && $res ne '-'){
					if($res eq $maf_nt){
						print MSA_HTML "<td width=5><b><font face='Courier New' color='#A51586' size=2><span style='background: #15A534;'>$res</span></font></b></td>\n";
					}else{
						print MSA_HTML "<td width=5><b><font face='Courier New' color='white' size=2><span style='background: #15A534;'>$res</span></font></b></td>\n";
					}
				}elsif($snp_val_f{$pos+1}{nval}){
					if($res eq $maf_nt){
						print MSA_HTML "<td width=5><b><font face='Courier New' color='#769E07' size=2><span style='background: #2F079E;'>$res</span></font></b></td>\n";
					}else{
						print MSA_HTML "<td width=5><b><font face='Courier New' color='white' size=2><span style='background: #2F079E;'>$res</span></font></b></td>\n";
					}
				}elsif($gnm{$gnm}{$pos+1} && $snp_val_f{$pos+1}{val}){
					if($res eq $maf_nt){
						print MSA_HTML "<td width=5><b><font face='Courier New' color='#00cccc' size=2><span style='background: #CC0000;'>$res</span></font></b></td>\n";
					}else{
						print MSA_HTML "<td width=5><b><font face='Courier New' color='white' size=2><span style='background: #CC0000;'>$res</span></font></b></td>\n";
					}	
				}else{
					print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2>$res</font></b></td>\n";
				}
			}
			print MSA_HTML "</tr>\n\n";
		}

		print MSA_HTML "<td><b><font face='Courier New' color='black' size=2>SNP position</font></b></td>\n";
		for(my $pos=1; $pos <= length($seq{$sq_num[$sq_ref_idx]}); $pos++) {
			if($gnm{$sq_num[$sq_ref_idx]}{$pos} && !$gap{$pos-1} || $snp_val_f{$pos}{val} || $snp_val_f{$pos}{nval}){
				print MSA_HTML "<td width=5><font face='Courier New' color='black' size=2>$pos</font></td>\n";
			}else{
				print MSA_HTML "<td width=5><font face='Courier New' color='black' size=2>.</font></td>\n";
			}
		}
		print MSA_HTML "<table border=0><tr><td></td>\n";
		print MSA_HTML "<table border=0><tr><td></td>\n";
		print MSA_HTML "<table cellspacing=2 cellpadding=10 border=0><tr bgcolor=#DEDEDE><td colspan=2><b><font face='Courier New' color='black' size=3>Legend</font></b></td></tr>";
		print MSA_HTML "<td bgcolor=#F2671D></td><td><b><font face='Courier New' color='black' size=2>Reference Sequence</font></b></td>\n";
		print MSA_HTML "</tr><tr>\n";
		print MSA_HTML "<td bgcolor=#CC0000></td><td><b><font face='Courier New' color='black' size=2>Validated SNPs</font></b></td>\n";
		print MSA_HTML "</tr><tr>\n";
		print MSA_HTML "<td bgcolor=#2F079E></td><td><b><font face='Courier New' color='black' size=2>Non-validated SNPs</font></b></td>\n";
		print MSA_HTML "</tr><tr>\n";
		print MSA_HTML "<td bgcolor=#15A534></td><td><b><font face='Courier New' color='black' size=2>New SNPs</font></b></td>\n";
		print MSA_HTML "</tr><tr>\n";
		print MSA_HTML "<td bgcolor=#30CEF2></td><td><b><font face='Courier New' color='black' size=2>GAPs</font></b></td>\n";
		print MSA_HTML "</tr><tr>\n";
		print MSA_HTML "</tr></table><br></td><td>\n";
		print MSA_HTML "</tr><tr>\n";
	}else{
		my %gap;
		foreach my $gnm (keys %seq){
			my @gnm_sq=split(//,$seq{$gnm});
			for(my $pos=0; $pos<@gnm_sq; $pos++) {
				my $res = $gnm_sq[$pos];
				if($res eq '-'){
					$gap{$pos}++;
				}
			}
		}

		print MSA_HTML "<tr>\n";
		print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2><span style='background:#F2671D;'>$ncbi_tax_name ($acc_id)</span></font></b></td>\n";
		my @gnm_sq=split(//,$seq{$sq_num[$sq_ref_idx]});
		for(my $pos=0; $pos<@gnm_sq; $pos++) {
			my $res = $gnm_sq[$pos];
			my $maf_nt = $maf_nt{$pos};
			if($gap{$pos} && $res eq '-'){
				print MSA_HTML "<td width=5><b><font face='Courier New' color='#30CEF2' size=2>$res</font></b></td>\n";
			}elsif($gap{$pos} && $res ne '-'){
				print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2>$res</font></b></td>\n";
			}elsif($gnm{$sq_num[$sq_ref_idx]}{$pos+1} && $snp_other{$pos+1} && !$gap{$pos}){

				if($res eq $maf_nt){
					print MSA_HTML "<td width=5><b><font face='Courier New' color='#A51586' size=2><span style='background: #15A534;'>$res</span></font></b></td>\n";
				}else{
					print MSA_HTML "<td width=5><b><font face='Courier New' color='white' size=2><span style='background: #15A534;'>$res</span></font></b></td>\n";
				}

			}else{
				print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2>$res</font></b></td>\n";
			}
		}
		print MSA_HTML "</tr>\n\n";


		foreach my $gnm (keys %seq){
			next if ($gnm =~ /\.@\./);
			my @sq_anlz = split ('.fa', $gnm);
			print MSA_HTML "<tr>\n";
			print MSA_HTML "<td><b><font face='Courier New' color='black' size=2>", $sq_anlz[0], "</font></b></td>\n";
			my @gnm_sq=split(//,$seq{$gnm});
			for(my $pos=0; $pos<@gnm_sq; $pos++) {
				my $res = $gnm_sq[$pos];
				my $maf_nt = $maf_nt{$pos};
				if($gap{$pos} && $res eq '-'){
					print MSA_HTML "<td width=5><b><font face='Courier New' color='#30CEF2' size=2>$res</font></b></td>\n";
				}elsif($gap{$pos} && $res ne '-'){
					print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2>$res</font></b></td>\n";
				}elsif($gnm{$sq_num[$sq_ref_idx]}{$pos+1} && $snp_other{$pos+1} && !$gap{$pos}){

					if($res eq $maf_nt){
						print MSA_HTML "<td width=5><b><font face='Courier New' color='#A51586' size=2><span style='background: #15A534;'>$res</span></font></b></td>\n";
					}else{
						print MSA_HTML "<td width=5><b><font face='Courier New' color='white' size=2><span style='background: #15A534;'>$res</span></font></b></td>\n";
					}

				}else{
					print MSA_HTML "<td width=5><b><font face='Courier New' color='black' size=2>$res</font></b></td>\n";
				}
			}
			print MSA_HTML "</tr>\n\n";
		}

		print MSA_HTML "<td><b><font face='Courier New' color='black' size=2>SNP position</font></b></td>\n";
		for(my $pos=1; $pos <= length($seq{$sq_num[$sq_ref_idx]}); $pos++) {
			if($gnm{$sq_num[$sq_ref_idx]}{$pos} && !$gap{$pos-1}){
				print MSA_HTML "<td width=5><font face='Courier New' color='black' size=2>$pos</font></td>\n";
			}else{
				print MSA_HTML "<td width=5><font face='Courier New' color='black' size=2>.</font></td>\n";
			}
		}

		print MSA_HTML "<table border=0><tr><td></td>\n";
		print MSA_HTML "<table border=0><tr><td></td>\n";
		print MSA_HTML "<table cellspacing=2 cellpadding=10 border=0><tr bgcolor=#DEDEDE><td colspan=2><b><font face='Courier New' color='black' size=3>Legend</font></b></td></tr>";
		print MSA_HTML "<td bgcolor=#F2671D></td><td><b><font face='Courier New' color='black' size=2>Reference Sequence</font></b></td>\n";
		print MSA_HTML "</tr><tr>\n";
		print MSA_HTML "<td bgcolor=#15A534></td><td><b><font face='Courier New' color='black' size=2>Detected SNPs</font></b></td>\n";
		print MSA_HTML "</tr><tr>\n";
	}
	print MSA_HTML "</body>\n<html>\n";
	close MSA_HTML;

	return ($m_type);

}

1;
