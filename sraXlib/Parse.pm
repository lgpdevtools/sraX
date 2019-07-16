#!/usr/bin/perl
package sraXlib::Parse;
use strict;
use warnings;
use sraXlib::Functions;
use sraXlib::Plot;

sub f_parse {
my ($d_gnm,$d_out,$idty,$cvrg,$a_type)=@_;


my $t_start_time_sf = sraXlib::Functions::running_time;
my $d_start_time_sf = sraXlib::Functions::print_time;
print "\nThe creation of summary files started at:\t$d_start_time_sf\n\n";

open (IN, "$d_out/Analysis/Homology_Search/sraX_hs.tsv") || die "[ERROR]: The homology search output file 'sraX_hs.tsv' is not inside its folder: $!\n";

my (%amr_db_cog_id, %amr_db,
    %gnm_id, %non_redun, %uniq, 
    %cog,%corrct);

while (my $line=<IN>){
	chomp $line;
	my @dat = split(/\t/, $line);
	next if ($dat[0] eq "Fasta_file");
	next if ($dat[8] < $cvrg);
        next if ($dat[9] < $idty);
                if($dat[2]>$dat[3]){
		$corrct{$dat[0]}{$dat[1]}{$dat[2]}{$dat[3]}++;
                my $s_corr = $dat[2];
                $dat[2] = $dat[3];
                $dat[3] = $s_corr;
                }
	push (@{ $amr_db_cog_id{$dat[0]}{$dat[1]}{$dat[2]}{$dat[3]} }, $line);
	$amr_db{$dat[0]}{$dat[1]}{$dat[2]}{$dat[3]}{$dat[8]}{$dat[9]} = $line;
	$gnm_id{$dat[0]}++;
}
close IN;

foreach my $gnm (sort {lc $a cmp lc $b} keys %amr_db){
        foreach my $cng (sort {lc $a cmp lc $b} keys %{$amr_db{$gnm}}){
                foreach my $start (sort { $a <=> $b } keys %{$amr_db{$gnm}{$cng}}){
                        foreach my $end (sort { $a <=> $b } keys %{$amr_db{$gnm}{$cng}{$start}}){
                                foreach my $cov (sort { $b <=> $a } keys %{$amr_db{$gnm}{$cng}{$start}{$end}}){
                                        foreach my $idy (sort { $b <=> $a } keys %{$amr_db{$gnm}{$cng}{$start}{$end}{$cov}}){
						my $data = $amr_db{$gnm}{$cng}{$start}{$end}{$cov}{$idy};
						my @dat = split(/\t/, $data);
						push (@{$non_redun{$dat[0]}{$dat[1]}{$dat[2]}{$dat[3]}{$dat[8]}{$dat[9]}}, $data);
                                        }
				}
			}
                }
        }
}

foreach my $gnm (sort {lc $a cmp lc $b} keys %non_redun){
        foreach my $cng (sort {lc $a cmp lc $b} keys %{$non_redun{$gnm}}){
                foreach my $start (sort { $a <=> $b } keys %{$non_redun{$gnm}{$cng}}){
                        foreach my $end (sort { $a <=> $b } keys %{$non_redun{$gnm}{$cng}{$start}}){
                                foreach my $cov (sort { $b <=> $a } keys %{$non_redun{$gnm}{$cng}{$start}{$end}}){
                                        foreach my $idy (sort { $b <=> $a } keys %{$non_redun{$gnm}{$cng}{$start}{$end}{$cov}}){
                                                for my $i ( 0 .. $#{ $non_redun{$gnm}{$cng}{$start}{$end}{$cov}{$idy} } ){
							unless(exists $uniq{$gnm}{$cng}{$start}{$end}){
							my $data = $non_redun{$gnm}{$cng}{$start}{$end}{$cov}{$idy}[$i];
                                                        my @dat = split(/\t/, $data);
							$cog{$dat[0]}{$dat[1]}{$dat[2]}{$dat[3]} = $data;
                                                        }
                                                	$uniq{$gnm}{$cng}{$start}{$end}++;
                                                }
                                        }
                                }
                        }
                }
        }
}

my %cog_2;
my $pos=1;
foreach my $gnm (sort {lc $a cmp lc $b} keys %cog){
        foreach my $cng (sort {lc $a cmp lc $b} keys %{$cog{$gnm}}){
                foreach my $start (sort { $a <=> $b } keys %{$cog{$gnm}{$cng}}){
                        foreach my $end (sort { $a <=> $b } keys %{$cog{$gnm}{$cng}{$start}}){
			$cog_2{$pos} = $cog{$gnm}{$cng}{$start}{$end};
			$pos++;			
			}
		}
	}
}

my %cog_to_reassign;
my %cog_by_cog;
my %cog_by_gene;
my %uniq_amr;
my $cog_id_cog = 1;
foreach my $pos (sort {$a <=>$b} keys %cog_2){
	my $actual_line	= $cog_2{$pos};
	my $next_line   = "";
	if($pos == (sort {$a <=>$b} keys %cog_2)[-1]){
	$next_line   = $actual_line;
	}else{
	$next_line   = $cog_2{$pos+1};
	}

	my @dat_actual	= split(/\t/, $actual_line);
	my @dat_next 	= split(/\t/, $next_line);
	
        if($dat_actual[2]>$dat_actual[3]){
        my $s_corr = $dat_actual[2];
        $dat_actual[2] = $dat_actual[3];
        $dat_actual[3] = $s_corr;
        }

	if($dat_next[2]>$dat_next[3]){
        my $s_corr = $dat_next[2];
        $dat_next[2] = $dat_next[3];
        $dat_next[3] = $s_corr;
        }

	my ($st_ac,$ed_ac) = ($dat_actual[2], $dat_actual[3]);
        my ($st_nx,$ed_nx) = ($dat_next[2], $dat_next[3]);
	my ($gn_length_ac, $gn_length_nx) = (($ed_ac-$st_ac),($ed_nx-$st_nx));

	if(($dat_actual[0] eq $dat_next[0]) && ($dat_actual[1] eq $dat_next[1])){
	my ($ov_ac,$ov_nx) = ("","");
		
		if($st_nx >= $ed_ac){
		($ov_ac,$ov_nx) = (0,0);
		}elsif($st_ac == $st_nx && $ed_ac == $ed_nx){
		$ov_ac = (($ed_ac-$st_ac)/$gn_length_ac);
		$ov_nx = (($ed_nx-$st_nx)/$gn_length_nx);
		}elsif($st_ac == $st_nx && $ed_ac < $ed_nx){
		$ov_ac = (($ed_ac-$st_ac)/$gn_length_ac);
                $ov_nx = (($ed_ac-$st_nx)/$gn_length_nx);
                }elsif($st_ac > $st_nx && $ed_ac == $ed_nx){
		$ov_ac = (($ed_ac-$st_ac)/$gn_length_ac);
                $ov_nx = (($ed_nx-$st_ac)/$gn_length_nx);
                }elsif($st_ac == $st_nx && $ed_ac > $ed_nx){
		$ov_ac = (($ed_nx-$st_ac)/$gn_length_ac);
                $ov_nx = (($ed_nx-$st_nx)/$gn_length_nx);
                }elsif($st_ac < $st_nx && $ed_ac == $ed_nx){
		$ov_ac = (($ed_ac-$st_nx)/$gn_length_ac);
		$ov_nx = (($ed_nx-$st_nx)/$gn_length_nx);
                }elsif($st_ac > $st_nx && $ed_ac > $ed_nx){
		$ov_ac = (($ed_nx-$st_ac)/$gn_length_ac);
		$ov_nx = (($ed_nx-$st_ac)/$gn_length_nx);
                }elsif($st_ac < $st_nx && $ed_ac < $ed_nx){
		$ov_ac = (($ed_ac-$st_nx)/$gn_length_ac);
                $ov_nx = (($ed_ac-$st_nx)/$gn_length_nx);
                }elsif($st_ac > $st_nx && $ed_ac < $ed_nx){
		$ov_ac = (($ed_ac-$st_ac)/$gn_length_ac);
                $ov_nx = (($ed_ac-$st_ac)/$gn_length_nx);	
                }elsif($st_ac < $st_nx && $ed_ac > $ed_nx){
		$ov_ac = (($ed_nx-$st_nx)/$gn_length_ac);
                $ov_nx = (($ed_nx-$st_nx)/$gn_length_nx);
		}else{
                }
			if($ov_ac <= 0.15 && $ov_nx <= 0.15){
				push (@{$cog_by_cog{$cog_id_cog}}, $dat_actual[4]);
				push (@{$cog_to_reassign{$cog_id_cog}}, $actual_line);
				$uniq_amr{ac}{$dat_actual[4]}{$dat_actual[11]} = "A\t$cog_id_cog";
				$cog_id_cog++;
				push (@{$cog_by_cog{$cog_id_cog}}, $dat_next[4]);
				push (@{$cog_to_reassign{$cog_id_cog}}, $next_line);
				$uniq_amr{nx}{$dat_next[4]}{$dat_next[11]} = "B\t$cog_id_cog";

			}else{
				unless(exists $uniq_amr{nx}{$dat_actual[4]}{$dat_actual[11]}){
                        	push (@{$cog_by_cog{$cog_id_cog}}, $dat_actual[4]);
                        	push (@{$cog_to_reassign{$cog_id_cog}}, $actual_line);
				push (@{$cog_by_cog{$cog_id_cog}}, $dat_next[4]);
				push (@{$cog_to_reassign{$cog_id_cog}}, $next_line);
				}else{
				push (@{$cog_by_cog{$cog_id_cog}}, $dat_next[4]);
                                push (@{$cog_to_reassign{$cog_id_cog}}, $next_line);
				}
			$uniq_amr{ac}{$dat_actual[4]}{$dat_actual[11]} = "C\t$cog_id_cog";
			$uniq_amr{nx}{$dat_next[4]}{$dat_next[11]} = "D\t$cog_id_cog";
                        }
	}else{
		if(exists $uniq_amr{nx}{$dat_actual[4]}{$dat_actual[11]}){
                $cog_id_cog++;
                push (@{$cog_by_cog{$cog_id_cog}}, $dat_next[4]);
                push (@{$cog_to_reassign{$cog_id_cog}}, $next_line);
		}else{
		push (@{$cog_by_cog{$cog_id_cog}}, $dat_actual[4]);
		push (@{$cog_to_reassign{$cog_id_cog}}, $actual_line);
		$cog_id_cog++;
                push (@{$cog_by_cog{$cog_id_cog}}, $dat_next[4]);
                push (@{$cog_to_reassign{$cog_id_cog}}, $next_line);
		}
	}
}

my %uniq_cog;
my %cog_corr;
my %cog_by_cog_2;
foreach my $cog_id (sort {$a<=>$b} keys %cog_by_cog){
	for my $i ( 0 .. $#{ $cog_by_cog{$cog_id} } ){
		unless(exists $uniq_cog{$cog_by_cog{$cog_id}[$i]}){
		$cog_corr{$cog_by_cog{$cog_id}[$i]} = $cog_id;
		push (@{$cog_by_cog_2{$cog_id}}, "$cog_id\t$cog_by_cog{$cog_id}[$i]");
		}else{
		push (@{$cog_by_cog_2{$cog_corr{$cog_by_cog{$cog_id}[$i]}}}, "$cog_id\t$cog_by_cog{$cog_id}[$i]");
		}
		$uniq_cog{$cog_by_cog{$cog_id}[$i]}++;			
	}
}

my %uniq_cog_2;
my %cog_reasign;
my $cog_id_cog_2 = 1;
foreach my $cog_id (sort {$a<=>$b} keys %cog_by_cog_2){
        for my $i ( 0 .. $#{ $cog_by_cog_2{$cog_id} } ){
		my ($cog_id_orig,$amr_gene)=split("\t",$cog_by_cog_2{$cog_id}[$i]);
		unless(exists $uniq_cog_2{$cog_id_cog_2}{$cog_id_orig}){
		push (@{$cog_reasign{$cog_id_orig}}, $cog_id_cog_2);
		}
		$uniq_cog_2{$cog_id_cog_2}{$cog_id_orig}++;
	}
	$cog_id_cog_2++;
}

my %cog_by_cog_3;
my %uniq_cog_3;
foreach my $cog_id (sort {$a<=>$b} keys %cog_reasign){
        for my $i ( 0 .. $#{ $cog_reasign{$cog_id} } ){
		unless(exists $uniq_cog_3{$cog_id}){
		push (@{$cog_by_cog_3{$cog_reasign{$cog_id}[$i]}}, $cog_id);
		}
		$uniq_cog_3{$cog_id}++;
        }
}

my %cog_id_new;
my $cog_id_new = 1;
foreach my $cog_id (sort {$a<=>$b} keys %cog_by_cog_3){
        for my $i ( 0 .. $#{ $cog_by_cog_3{$cog_id} } ){
	$cog_id_new{$cog_by_cog_3{$cog_id}[$i]} = $cog_id_new;
	}
	$cog_id_new++;
}

my %cog_id_new_2;
foreach my $cog_id (sort {$a<=>$b} keys %cog_to_reassign){
        for my $i ( 0 .. $#{ $cog_to_reassign{$cog_id} } ){
		push (@{$cog_id_new_2{$cog_id_new{$cog_id}}}, $cog_to_reassign{$cog_id}[$i]);
	}
}

my %cog_id_infile;
foreach my $cog_id (sort {$a<=>$b} keys %cog_id_new_2){
        for my $i ( 0 .. $#{ $cog_id_new_2{$cog_id} } ){
	my @dat  = split(/\t/, $cog_id_new_2{$cog_id}[$i]); 
	$cog_id_infile{$dat[0]}{$dat[1]}{$dat[2]}{$dat[3]} = $cog_id;
	}
}

my (%uniq_var, %cogs, %uniq_cogs, %cog_id, %sorted_hits, %sorted_hits_data);
my $cog_idr = 0;
foreach my $gnm (sort {lc $a cmp lc $b} keys %amr_db_cog_id){
        foreach my $cng (sort {lc $a cmp lc $b} keys %{$amr_db_cog_id{$gnm}}){
                foreach my $start (sort { $a <=> $b } keys %{$amr_db_cog_id{$gnm}{$cng}}){
                        foreach my $end (sort { $a <=> $b } keys %{$amr_db_cog_id{$gnm}{$cng}{$start}}){
				for my $i ( 0 .. $#{ $amr_db_cog_id{$gnm}{$cng}{$start}{$end} } ){
				my @dat = split(/\t/, $amr_db_cog_id{$gnm}{$cng}{$start}{$end}[$i]);
					my $cog_id = $cog_id_infile{$dat[0]}{$dat[1]}{$dat[2]}{$dat[3]};
                                        if(defined $cog_id){
                                                unless(exists $uniq_var{$dat[11]}){
                                                $cogs{$dat[11]} = $cog_id;
                                                        unless(exists $uniq_cogs{$cog_id}){
                                                        $cog_idr++;
                                                        $cog_id{$cogs{$dat[11]}} = $cog_idr;
                                                        }
                                                        $uniq_cogs{$cog_id}++;
                                                }
                                                $uniq_var{$dat[11]}++;
                                        }else{
                                        }
                                        if(defined $cog_id{$cogs{$dat[11]}}){
					$sorted_hits{$dat[13]}{$dat[10]}{$dat[4]} = $cog_id{$cogs{$dat[11]}};
                                        push (@{ $sorted_hits_data{$cog_id{$cogs{$dat[11]}}} }, $amr_db_cog_id{$gnm}{$cng}{$start}{$end}[$i]);
					}else{
                                        print "$amr_db_cog_id{$gnm}{$cng}{$start}{$end}[$i]\n";
                                        }
				}
			}
		}
	}
}

my (%uniq_gn_id,%sorted_hits_f);
my $cog_idr_f = 0;
foreach my $model (sort {lc $a cmp lc $b} keys %sorted_hits){
	foreach my $class (sort {lc $a cmp lc $b} keys %{$sorted_hits{$model}}){
		foreach my $gene (sort {lc $a cmp lc $b} keys %{$sorted_hits{$model}{$class}}){
			unless(exists $uniq_gn_id{$sorted_hits{$model}{$class}{$gene}}){
			$cog_idr_f++;
				for my $i ( 0 .. $#{ $sorted_hits_data{$sorted_hits{$model}{$class}{$gene}} } ){
				$sorted_hits_f{$sorted_hits_data{$sorted_hits{$model}{$class}{$gene}}[$i]} = $cog_idr_f;
                        	}
			}
			$uniq_gn_id{$sorted_hits{$model}{$class}{$gene}}++;
		}
	}
}

my %filt_last;
foreach my $gnm (sort {lc $a cmp lc $b} keys %amr_db_cog_id){
        foreach my $cng (sort {lc $a cmp lc $b} keys %{$amr_db_cog_id{$gnm}}){
                foreach my $start (sort { $a <=> $b } keys %{$amr_db_cog_id{$gnm}{$cng}}){
                        foreach my $end (sort { $a <=> $b } keys %{$amr_db_cog_id{$gnm}{$cng}{$start}}){
                                for my $i ( 0 .. $#{ $amr_db_cog_id{$gnm}{$cng}{$start}{$end} } ){
                                my @dat = split(/\t/, $amr_db_cog_id{$gnm}{$cng}{$start}{$end}[$i]);
                                        if(defined $cog_id{$cogs{$dat[11]}}){
				push (@{ $filt_last{$sorted_hits_f{$amr_db_cog_id{$gnm}{$cng}{$start}{$end}[$i]}}{$dat[0]}{$dat[1]}{$dat[8]}{$dat[9]} }, $amr_db_cog_id{$gnm}{$cng}{$start}{$end}[$i]);
                                        }else{
                                        print "$amr_db_cog_id{$gnm}{$cng}{$start}{$end}[$i]\n";
                                        }
                                }
                        }
                }
        }
}

my $gn_coord = "$d_out/Results/Summary_files/sraX_gene_coordinates.tsv";
open(F1,">$gn_coord") || die "[ERROR]: The output file $gn_coord cannot be created: $!\n";
print F1 "Locus_ID\tGenome\tContig\tStart_query\tEnd_query\tAMR_gene\tCoverage\tStatus_hit\t";
print F1 "Num_gaps\tCoverage_p\tIdentity_p\tAMR_Class\tAccession_ID\tGene_description\tAMR_detection_model\tMetadata\n";
my $cog_id_dtctd_gn = "$d_out/Results/Summary_files/sraX_blastx_output.tsv";
open(F6,">$cog_id_dtctd_gn") || die "[ERROR]: The output file $cog_id_dtctd_gn cannot be created: $!\n";
print F6 "Locus ID\tFasta file\tContig\tStart query\tEnd query\tARG\tCoverage\tStatus hit\t";
print F6 "# gaps\tCoverage (%)\tIdentity (%)\tAMR Class\tAccession ID\tGene description\tAMR detection model\tMetadata\n";

my %msa;
my %gnm_table_hm;
my %gn_list;
my %plgs;
my %uniq_cog_4;
my @st_hit;
foreach my $cog_id (sort {$a<=>$b} keys %filt_last){
	foreach my $gnm (sort {lc $a cmp lc $b} keys %{$filt_last{$cog_id}}){
		foreach my $cng (sort sort {lc $a cmp lc $b} keys %{$filt_last{$cog_id}{$gnm}}){
			foreach my $cov (sort {$b<=>$a} keys %{$filt_last{$cog_id}{$gnm}{$cng}}){
				foreach my $idy (sort {$b<=>$a} keys %{$filt_last{$cog_id}{$gnm}{$cng}{$cov}}){
					for my $i ( 0 .. $#{ $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy} } ){
					my @dat  = split(/\t/, $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy}[$i]);
					my $locus = $dat[4];
					my @locus = split(/\_/, $locus);
					unless($dat[13] eq 'protein_homolog'){
					$locus = $locus[2];
						if($dat[13] eq 'protein_overexpression' && scalar @locus <= 3){
						$locus = $dat[4];
						}
					}
                			my @class = split(/\_/, $dat[10]);
                			unless(scalar @class == 1){
                			$dat[10] = $class[0];
                			}
                			$dat[12] =~s/\_/ /g;
                			$dat[13] =~s/\_/ /g;

						# Correction: 25.06.2019 
						if ($locus eq ''){
						$locus = $dat[4];
						}

					print F6 "$cog_id\t$filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy}[$i]\n";
                                                unless(exists $uniq_cog_4{$cog_id}{$gnm}){
						print F1 "$cog_id\t$dat[0]\t$dat[1]\t$dat[2]\t$dat[3]\t$locus\t$dat[5]\t$dat[6]\t$dat[7]\t$dat[8]\t$dat[9]\t$dat[10]\t$dat[11]\t$dat[12]\t$dat[13]\n";
						@st_hit = split(/\t/, $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy}[$i]);
						push @{ $msa{$cog_id} }, $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy}[$i];
                                                $gnm_table_hm{$cog_id}{$gnm} = "$cov\t$idy";
						push @{ $gn_list{$cog_id} }, $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy}[$i];
						push @{ $plgs{$gnm}{$cog_id} }, $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy}[$i];
                                                }else{
							if($st_hit[4] eq $dat[4] && $st_hit[11] eq $dat[11]){
							print F1 "$cog_id (Paralog copy)\t$dat[0]\t$dat[1]\t$dat[2]\t$dat[3]\t$locus\t$dat[5]\t$dat[6]\t$dat[7]\t$dat[8]\t$dat[9]\t$dat[10]\t$dat[11]\t$dat[12]\t$dat[13]\n";
							push @{ $plgs{$gnm}{$cog_id} }, $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy}[$i];
							}
						}
                                                $uniq_cog_4{$cog_id}{$gnm}++;
					}
				}
			}
		}
	}
}
close F1;
close F6;

my $prlg = "$d_out/Results/Summary_files/sraX_putative_paralogs.tsv";
open(F2,">$prlg") || die "[ERROR]: The output file $prlg cannot be created: $!\n";
print F2 "Locus_ID\tFasta_file\tContig\tStart_query\tEnd_query\tAMR_gene\tCoverage\tStatus_hit\t";
print F2 "Num_gaps\tCoverage_%\tIdentity_%\tAMR_Database\tAccession_ID\tGene_description\tAMR_Type\n";
foreach my $gnm (sort {lc $a cmp lc $b} keys %plgs){
       foreach my $cog_id (sort {$a <=> $b} keys %{$plgs{$gnm}}){
       my $size = scalar( @{ $plgs{$gnm}{$cog_id} } );
       next if $size == 1;
               for my $i ( 0 .. $#{ $plgs{$gnm}{$cog_id} } ){
               print F2 "$plgs{$gnm}{$cog_id}[$i]\n";
               }
       }
}
close F2;

my $gn_dtcd = "$d_out/Results/Summary_files/sraX_detected_ARGs.tsv";
open(F3,">$gn_dtcd") || die "[ERROR]: The output file $gn_dtcd cannot be created: $!\n";
print F3 "Locus ID\t# Sequences\tARG\tCoverage (%)\tIdentity (%)\tDrug class\tGene accession ID\tGene description\tAMR detection model\n";

my %non_prlg;
my %gnm_table;
foreach my $cog_id (sort {$a<=>$b} keys %gn_list){
        my $size = scalar( @{ $gn_list{$cog_id} } );
        my @dat  = split(/\t/, $gn_list{$cog_id}[0]);
		my $locus = $dat[4];
		my @locus = split(/\_/, $locus);
		unless($dat[13] eq 'protein_homolog'){
                $locus = $locus[2];
                        if($dat[13] eq 'protein_overexpression' && scalar @locus <= 3){
                        $locus = $dat[4];
                        }
                }

			# Correction: 25.06.2019 
                        if ($locus eq ''){
                        $locus = $dat[4];
                        }

		my @class = split(/\_/, $dat[10]);
		unless(scalar @class == 1){
                $dat[10] = $class[0];
                }
		$dat[12] =~s/\_/ /g;
        	$dat[13] =~s/\_/ /g;
	$gnm_table{$dat[4]} = "$cog_id\t$size\t$locus\t$dat[10]\t$dat[11]\t$dat[12]\t$dat[13]";
	print F3 "$cog_id\t$size\t$dat[4]\t$dat[8]\t$dat[9]\t$dat[10]\t$dat[11]\t$dat[12]\t$dat[13]\n";
}
close F3;

my $t_stop_time_sf = sraXlib::Functions::running_time;
print "\n\tThe creation of summary files took ";
printf("%.2f ", $t_stop_time_sf - $t_start_time_sf);
print " wallclock secs\n\n";
my $d_stop_time_sf = sraXlib::Functions::print_time;
print "\nThe creation of summary files finished at:\t$d_stop_time_sf\n\n";

my $t_start_time_sp = sraXlib::Functions::running_time;
my $d_start_time_sp = sraXlib::Functions::print_time;
print "\nThe creation of HTML files plus embedded summary plots started at:\t$d_start_time_sp\n\n";

my $gn_dtcdhtml = "$d_out/Results/sraX_analysis.html";
open(HTML,">$gn_dtcdhtml") || die "[ERROR]: The output file $gn_dtcdhtml cannot be created: $!\n";

print HTML "<html>\n<head>\n</head>\n<body>\n\n";
print HTML "<table id='detected_genes'><tbody><tr bgcolor=#DEDEDE><td style='text-align:center' colspan=11><b>Detected ARGs</b>";
print HTML "<tr style='text-align:center' bgcolor=#DEDEDE><td><b>Locus ID<b><td><b># of Seq.<b><td><b>ARG<b><td><b>Drug class<b>";
print HTML "<td><b>Target species<b><td><b>Gene accession ID<b><td><b>Gene description<b><td><b>Seq. coverage (%)<b><td><b>Seq. identity (%)<b><td><b>MSA alignment<b><td><b>AMR linked to SNP?<b></td></tr>\n";

foreach my $cog_id (sort {$a<=>$b} keys %gn_list){
	my $size = scalar( @{ $gn_list{$cog_id} } );
	my @dat  = split(/\t/, $gn_list{$cog_id}[0]);
	my $locus = $dat[4];
	my @locus = split(/\_/, $locus);
	unless($dat[13] eq 'protein_homolog'){
        $locus = $locus[2];
                if($dat[13] eq 'protein_overexpression' && scalar @locus <= 3){
                $locus = $dat[4];
                }
        }
        my @class = split(/\_/, $dat[10]);
        unless(scalar @class == 1){
        $dat[10] = $class[0];
        }
	$dat[12] =~s/\_/ /g;
        $dat[13] =~s/\_/ /g;
	my ($aro_id,$card_tax_id,$ncbi_tax_name,$ncbi_tax_id);
	my @mdat = split(/\_/, $dat[$#dat]);
	if($mdat[0] =~ m/^\d+$/ && $mdat[1] =~ m/^\d+$/){
	($aro_id,$card_tax_id,$ncbi_tax_name,$ncbi_tax_id) = ($mdat[0],$mdat[1],$mdat[2],$mdat[3]);
		if(defined $ncbi_tax_name){
                $ncbi_tax_name =~s/\.\./ /g;
                }
	}else{
	$ncbi_tax_name = $dat[$#dat];
	($aro_id,$card_tax_id,$ncbi_tax_id) = ("Not_indicated", "Not_indicated","Not_indicated");
	}

	my $msa_html_dna = "Analysis/MSA/DNA/SNP/Locus_$cog_id"."_dna.html";
	my $msa_html_aa  = "Analysis/MSA/AA/SNP/Locus_$cog_id"."_aa.html";

  		unless($cog_id % 2){
		print HTML "<tr bgcolor=#d8d8da>";
		}else{
		print HTML "<tr>";
		}

		print HTML "<td align=center><a href=../Analysis/Homology_Search/Individual_ARGs/Locus_$cog_id.html target='_blank'>$cog_id</a><td align=center>$size";
	
		unless($aro_id eq "Not_indicated"){
		print HTML "<td><a href=https://card.mcmaster.ca/ontology/$aro_id target='_blank'>$locus</a>";
		print HTML "<td>$dat[10]";
		print HTML "<td><a href=https://card.mcmaster.ca/ontology/$card_tax_id target='_blank'><i>$ncbi_tax_name<i></a>";
		}else{
		print HTML "<td>$locus<td>$dat[10]<td><i>$ncbi_tax_name<i></>";
		}
		
		print HTML "<td><a href=https://www.ncbi.nlm.nih.gov/protein/$dat[11] target='_blank'>$dat[11]</a>";
		print HTML "<td>$dat[12]<td align=center>$dat[8]<td align=center>$dat[9]";
		print HTML "<td><a href=../$msa_html_dna target='_blank'>[DNA,</a>";
		
		if($dat[13] eq "rRNA gene variant"){
		print HTML " --]</a>\n";
		}else{
		print HTML "<a href=../$msa_html_aa target='_blank'> AA]</a>";
		}

		if ($dat[10]=~m/Mutation/i){
		print HTML "<td><b>Yes<b></td></tr>\n";
		}else{
		print HTML "<td>No</td></tr>\n";
		}

}

print HTML "<table border=0><tr><td></td>\n";
print HTML "<table border=0><tr><td></td>\n";
print HTML "<table border=0><tr><td></td>\n";
print HTML "<table border=0><tr><td></td>\n";


my $cog_row = 0;
my %uniq_cog_5;
foreach my $cog_id (sort {$a<=>$b} keys %filt_last){
open(GN_HTML,">$d_out/Analysis/Homology_Search/Individual_ARGs/Locus_$cog_id.html") || die "[ERROR]: The output file 'Locus_$cog_id.html' cannot be created: $!\n";

print GN_HTML "<html>\n<head>\n</head>\n<body>\n\n";
print GN_HTML "<table id='detected_genes'><tbody><tr bgcolor=#DEDEDE><td style='text-align:center' colspan=13><b>Detected ARGs</b>";
print GN_HTML "<tr style='text-align:center' bgcolor=#DEDEDE><td><b>Gene ID<b><td><b>ARG<b><td><b>Gene description<b><td><b>Gene accession ID<b>";
print GN_HTML "<td><b>Genome<b><td><b>Contig ID<b><td><b>Start query<b><td><b>End query<b><td><b>Coverage<b><td><b># gaps<b>";
print GN_HTML "<td><b>Seq. coverage (%)<b><td><b>Seq. identity (%)<b><td><b>Comments<b></td></tr>\n";

        foreach my $gnm (sort {lc $a cmp lc $b} keys %{$filt_last{$cog_id}}){
                foreach my $cng (sort sort {lc $a cmp lc $b} keys %{$filt_last{$cog_id}{$gnm}}){
                        foreach my $cov (sort {$b<=>$a} keys %{$filt_last{$cog_id}{$gnm}{$cng}}){
                                foreach my $idy (sort {$b<=>$a} keys %{$filt_last{$cog_id}{$gnm}{$cng}{$cov}}){
				        for my $i ( 0 .. $#{ $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy} } ){
					my @dat  = split(/\t/, $filt_last{$cog_id}{$gnm}{$cng}{$cov}{$idy}[$i]);
        				my ($aro_id,$card_tax_id,$ncbi_tax_name,$ncbi_tax_id);
        				my @mdat = split(/\_/, $dat[$#dat]);
					if($mdat[0] =~ m/^\d+$/ && $mdat[1] =~ m/^\d+$/){
       	 				($aro_id,$card_tax_id,$ncbi_tax_name,$ncbi_tax_id) = ($mdat[0],$mdat[1],$mdat[2],$mdat[3]);
                				if(defined $ncbi_tax_name){
                				$ncbi_tax_name =~s/\.\./ /g;
                				}
        				}else{
        				$ncbi_tax_name = $dat[$#dat];
					($aro_id,$card_tax_id,$ncbi_tax_id) = ("Not_indicated", "Not_indicated","Not_indicated");
        				}
					$dat[12] =~s/_/ /g;
                                                unless(exists $uniq_cog_5{$cog_id}{$gnm}{$cng}){
                					$cog_row++;
                					unless($cog_row % 2){
                					print GN_HTML "<tr bgcolor=#d8d8da>";
                					}else{
                					print GN_HTML "<tr>";
                					}
						print GN_HTML "<td align=center>$cog_id<td><a href=https://card.mcmaster.ca/ontology/$aro_id target='_blank'>$dat[4]</a>";
						print GN_HTML "<td>$dat[12]<td align=center><a href=https://www.ncbi.nlm.nih.gov/protein/$dat[11] target='_blank'>$dat[11]</a>";
						print GN_HTML "<td>$dat[0]<td>$dat[1]<td>$dat[2]<td>$dat[3]<td>$dat[5]<td>$dat[7]<td align=center>$dat[8]<td align=center>$dat[9]<td>$dat[6]</td></tr>\n";

  						}
                                                $uniq_cog_5{$cog_id}{$gnm}{$cng}++;
                                        }
                                }
                        }
                }
        }
close GN_HTML;
}

my $htmp_pa = "$d_out/Results/Plots/Heatmaps/sraX_hmPA.tsv";
open(F4,">$htmp_pa") || die "[ERROR]: The output file $htmp_pa cannot be created: $!\n";
print F4 "Locus_ID\tNum_of_Seqs\tAMR_gene\tATB_Class\tAccession_ID\tGene_description\tAMR_detection_model\t";
print F4 join("\t", sort { lc $a cmp lc $b } keys %gnm_id)."\n";
my $htmp_id = "$d_out/Results/Plots/Heatmaps/sraX_hmSI.tsv";
open(F5,">$htmp_id") || die "[ERROR]: The output file $htmp_id cannot be created: $!\n";
print F5 "Locus_ID\tNum_of_Seqs\tAMR_gene\tATB_Class\tAccession_ID\tGene_description\tAMR_detection_model\t";
print F5 join("\t", sort { lc $a cmp lc $b } keys %gnm_id)."\n";
my $num_gnms = keys %gnm_id;
my $last_gnm = (sort {lc $a cmp lc $b} keys %gnm_id )[-1];

foreach my $amr_gn (sort {lc $a cmp lc $b} keys %gnm_table){
print F4 $gnm_table{$amr_gn}."\t";
print F5 $gnm_table{$amr_gn}."\t";
my @dat_r = split(/\t/, $gnm_table{$amr_gn});
        foreach my $gnm (sort {lc $a cmp lc $b} keys %gnm_id){
                if(exists $gnm_table_hm{$dat_r[0]}{$gnm}){
                my ($cov_r,$idty_r) = split(/\t/, $gnm_table_hm{$dat_r[0]}{$gnm});
                        unless($gnm eq $last_gnm){
                        print F4 "1\t";
                        print F5 "$idty_r\t";
                        }else{
                        print F4 "1";
                        print F5 "$idty_r";
                        }
                }else{
                        unless($gnm eq $last_gnm){
                        print F4 "0\t";
                        print F5 "0\t";
                        }else{
                        print F4 "0";
                        print F5 "0";
                        }
                }
        }
print F4 "\n";
print F5 "\n";
}
close F4;
close F5;

my ($htmp_pa_plot, $htmp_id_plot) = sraXlib::Plot::htmps($htmp_pa,$htmp_id); 

print HTML "<style>
img {
    width: 100%;
    height: auto;
}
</style>\n";

print HTML "<h2 align=center>Detected ARGs by Genome</h2>\n";
print HTML "<div style='width:100%; text-align:center'>\n";
print HTML "<img src='Plots/Heatmaps/$htmp_pa_plot' alt='Abs_Pres' align:center>\n";
print HTML "</div>\n";
print HTML "<table border=0><tr><td></td>\n";
print HTML "<table border=0><tr><td></td>\n";
print HTML "<h2 align=center>Prot. Seq. Ident. (%) of detected ARGs</h2>\n";
print HTML "<div style='width:100%; text-align:center'>\n";
print HTML "<img src='Plots/Heatmaps/$htmp_id_plot' alt='Seq_Ident' align:center>\n";
print HTML "</div>\n";
my ($arg_prop, $snp_prop) = sraXlib::Plot::prop_arg($gn_coord);
print HTML "<table border=0><tr><td></td>\n";
print HTML "<table border=0><tr><td></td>\n";
print HTML "<h2 align=center></h2>\n";
print HTML "<div style='width:100%; text-align:center'>\n";
print HTML "<img src='Plots/Proportion_ARG/$arg_prop' alt='Drug_Class' align:center>\n";
print HTML "</div>\n";
print HTML "<table border=0><tr><td></td>\n";
print HTML "<table border=0><tr><td></td>\n";
print HTML "<div style='width:120%; text-align:center'>\n";
print HTML "<img src='Plots/Proportion_ARG/$snp_prop' alt='SNP_Type' align:center>\n";
print HTML "</div>\n";

open (CTX, "$gn_coord") || die "[ERROR]: The output file 'sraX_gene_coord.tsv' is not inside its folder: $!\n";
my %gnm_ctx;
while (<CTX>){
	chomp;
	next if $. == 1;
	my @dat = split(/\t/, $_);
	push (@{ $gnm_ctx{$dat[1]} }, $_);
}
close CTX;

print HTML "<table border=0><tr><td></td>\n";
print HTML "<table border=0><tr><td></td>\n";
print HTML "<html>\n<head>\n</head>\n<body>\n\n";
print HTML "<table id='gnm_ctx'><tbody><tr bgcolor=#DEDEDE><td style='text-align:center'><b>Genomic context of detected ARGs<b></td></tr>\n";

my $arg_row = 0;
foreach my $gnm (sort {lc $a cmp lc $b} keys %gnm_ctx){
	print HTML "<td><a href=Plots/Genomic_Context/$gnm.html target='_blank'>$gnm</a></td></tr>\n";
open(CTX_HTML,">$d_out/Results/Plots/Genomic_Context/$gnm.html") || die "[ERROR]: The output file '$gnm.html' cannot be created: $!\n";
print CTX_HTML "<html>\n<head>\n</head>\n<body>\n\n";
print CTX_HTML "<table id='gnm_ctx'><tbody><tr bgcolor=#DEDEDE><td style='text-align:center' colspan=11><b>Detected ARGs</b>";
print CTX_HTML "<tr style='text-align:center' bgcolor=#DEDEDE><td><b>Locus ID<b><td><b>Genome<b><td><b>Contig<b><td><b>Start query<b>";
print CTX_HTML "<td><b>End query<b><td><b>ARG<b><td><b>Drug Class<b><td><b>Gene description<b><td><b>Seq. coverage (%)<b>";
print CTX_HTML "<td><b>Seq. identity (%)<b><td><b>AMR detection model<b></td></tr>\n";
	for my $i ( 0 .. $#{ $gnm_ctx{$gnm} } ){
	my $last_gn = $gnm_ctx{$gnm}[$#{ $gnm_ctx{$gnm} }];
	my @dat = split(/\t/, $gnm_ctx{$gnm}[$i]);
	my $locus = $dat[5];
        my @locus = split(/\_/, $locus);
	my @class = split(/\_/, $dat[11]);
        unless(scalar @class == 1){
        $dat[11] = $class[0];
        }
	$dat[13] =~s/_/ /g;
	$dat[14] =~s/_/ /g;
		$arg_row++;
		unless($arg_row % 2){
                print CTX_HTML "<tr bgcolor=#d8d8da>";
                }else{
                print CTX_HTML "<tr>";
                }
	print CTX_HTML "<td align=center>$dat[0]<td>$dat[1]<td>$dat[2]<td align=center>$dat[3]<td align=center>$dat[4]<td align=center>$locus";
	print CTX_HTML "<td>$dat[11]<td>$dat[13]<td align=center>$dat[9]<td align=center>$dat[10]<td>$dat[14]</td></tr>\n";
	}
        print CTX_HTML "<table border=0><tr><td></td>\n";
        print CTX_HTML "<table border=0><tr><td></td>\n";
	print CTX_HTML "<style>
	img {
    	width: 100%;
    	height: auto;
	}
	</style>\n";
	print CTX_HTML "<h2 align=center>Distribution of ARGs within the genome</h2>\n";
	print CTX_HTML "<div style='width:125%; height: auto; text-align:center'>\n";
	print CTX_HTML "<img src='$gnm.a.png' align:center>\n";
	print CTX_HTML "</div>\n";
	print CTX_HTML "<table border=0><tr><td></td>\n";
	print CTX_HTML "<table border=0><tr><td></td>\n";
	my $f_pres = sraXlib::Functions::check_file("$d_out/Results/Plots/Genomic_Context/$gnm.b.png");
        next unless($f_pres == 1);
	print CTX_HTML "<h2 align=center>Extensive  information of very distant (15000 bp) ARGs</h2>\n";
	print CTX_HTML "<div style='width:125%; height: auto; text-align:center'>\n";
	print CTX_HTML "<img src='$gnm.b.png' align:center>\n";
	print CTX_HTML "</div>\n";
	print CTX_HTML "<table border=0><tr><td></td>\n";
	print CTX_HTML "<table border=0><tr><td></td>\n";
}
close HTML;
close CTX_HTML;

my $t_stop_time_sp = sraXlib::Functions::running_time;
print "\n\tThe creation of HTML files plus embedded summary plots took ";
printf("%.2f ", $t_stop_time_sp - $t_start_time_sp);
print " wallclock secs\n\n";
my $d_stop_time_sp = sraXlib::Functions::print_time;
print "\nThe creation of HTML files plus embedded summary plots finished at:\t$d_stop_time_sp\n\n";
my $t_start_time_cls = sraXlib::Functions::running_time;
my $d_start_time_cls = sraXlib::Functions::print_time;
print "\nThe creation of sequence clusters started at:\t$d_start_time_cls\n\n";
print "\n\n\tClustering of homologous sequences for SNP detection\n";
print "\t                    'ARG ID'\t\t  'Cluster ID':\n";

foreach my $amr_gn (sort {lc $a cmp lc $b} keys %gnm_table){
        my ($cog_id,$num_sq,$amr_gn,$amr_db,$amr_gn_acc) = split(/\t/, $gnm_table{$amr_gn});
        print "\tProcessing the gene '$amr_gn'\t\t=> $cog_id\n";
                for my $i ( 0 .. $#{ $msa{$cog_id} } ){
                my @dat = split (/\t/, $msa{$cog_id}[$i]);
                parse_fasta($d_gnm,$d_out,$cog_id,$dat[0],$dat[4],$dat[1],$dat[2],$dat[3],$dat[11],$dat[13]);
                }
}

my $t_stop_time_cls = sraXlib::Functions::running_time;
print "\n\tThe creation of sequence clusters took ";
printf("%.2f ", $t_stop_time_cls - $t_start_time_cls);
print " wallclock secs\n\n";
my $d_stop_time_cls = sraXlib::Functions::print_time;
print "\nThe creation of sequence clusters finished at:\t$d_stop_time_cls\n\n";


}

my %not_dup_sq;
sub parse_fasta{
my ($d_gnm,$d_out,$cog_id,$gnm,$amr_gn,$contig,$start,$end,$acc_id,$m_type)=@_;
open (Locus_DNA, ">>$d_out/Analysis/MSA/DNA/Locus_$cog_id"."_dna.fa");
unless($m_type eq "rRNA_gene_variant"){
open (Locus_AA, ">>$d_out/Analysis/MSA/AA/Locus_$cog_id"."_aa.fa");
}

my ($amr_id_ref_aa,$amr_sq_ref_aa,$amr_id_ref_dna,$amr_sq_ref_dna) = sraXlib::Functions::load_db_gn("$d_out/ARG_DB",$amr_gn,$acc_id,$m_type);
unless(exists $not_dup_sq{$cog_id}){
	unless($m_type eq "rRNA_gene_variant"){
                unless($amr_id_ref_aa eq "" && $amr_sq_ref_aa eq ""){
                print Locus_AA ">$amr_id_ref_aa\n";
                print Locus_AA $amr_sq_ref_aa."\n";
                }else{
                print "Missing AA data !\n";
                }
		unless($amr_id_ref_dna eq "" && $amr_sq_ref_dna eq ""){
        	print Locus_DNA ">$amr_id_ref_dna\n";
        	print Locus_DNA $amr_sq_ref_dna."\n";
        	}else{
		print "Missing DNA data !\n";
        	}
        }else{
        	unless($amr_id_ref_dna eq "" && $amr_sq_ref_dna eq ""){
        	print Locus_DNA ">$amr_id_ref_dna\n";
        	print Locus_DNA $amr_sq_ref_dna."\n";
        	}else{
		print "Missing DNA data !\n";
        	}
	}
}
$not_dup_sq{$cog_id}++;
my $slct_cnt = sraXlib::Functions::load_contig($d_gnm,$gnm,$contig);
        my $header = $gnm."_".$amr_gn;
        my $len=length($slct_cnt);
	my $num_bases = 0;
	my $sub_seq="";
	if ($start > $end){
	$num_bases = $start-$end+1;
        print Locus_DNA ">$header"."_revcmp, gene_length = $num_bases bp, Putative AMR_gene: $end-$start\n";
	my $sub_seq_revcmp = sraXlib::Functions::revcmp(substr($slct_cnt, $end-1, $num_bases));
	print Locus_DNA $sub_seq_revcmp."\n";
		unless($m_type eq "rRNA_gene_variant"){
        	my $aa_sq_revcmp = sraXlib::Functions::get_aa_sq($sub_seq_revcmp);
        	my $len_aa_revcmp=length($aa_sq_revcmp);
        	print Locus_AA ">$header, protein_product=$len_aa_revcmp\n";
        	print Locus_AA $aa_sq_revcmp."\n";
		}
        }else{
	$num_bases = $end-$start+1;
        print Locus_DNA ">$header, gene_length = $num_bases bp, Putative AMR_gene: $start-$end\n";
        $sub_seq = substr($slct_cnt, $start-1, $num_bases);
        print Locus_DNA $sub_seq."\n";
		unless($m_type eq "rRNA_gene_variant"){
        	my $aa_sq_right = sraXlib::Functions::get_aa_sq($sub_seq);
        	my $len_aa_right=length($aa_sq_right);
        	print Locus_AA ">$header, protein_product=$len_aa_right\n";
        	print Locus_AA $aa_sq_right."\n";
		}
        }

close Locus_DNA;
close Locus_AA;
}

1;
