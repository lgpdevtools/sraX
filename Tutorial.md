# User Guide

### 1) Genome data acquisition from previously analyzed collections
In order to analyze the performance and efficacy of **sraX**, diverse public datasets, composed of a variable number of fasta assembly files belonging to different bacteria spp, are going to be acquired:

#### Dataset #1: 197 genomes belonging to _Enterococcus spp_ [1](#references)

   __Note__ The following steps are recurrent and should be followed for performing the **sraX** analysis with 
alternative genome datasets. The main modifications are the repository hyperlink and the name of the genome directory. 

   a) Download the compressed file: [dataset #1: _Enterococcus spp_](http://usegalaxy.sorbonne-universite.fr/nextcloud/index.php/s/PFLfFfkjiok9yxX/download)

   b) Using the bash console, extract the genome data into the working directory:

   ```
   tar -zxvf /download_full_path/Enterococcus_spp.tar.gz -C /working_dir_full_path/
   ```
   c) Run **sraX** using default options:

   ```
   sraX -i Enterococcus_spp
   ```

   d) Specifying particular desired options (like sequence identity percentage, alignment coverage, output result directory,
etc...):

   ```
   sraX -i Enterococcus_spp -id 75 -c 90 -o Enterococcus_spp_defined_options
   ```

#### Dataset #2: 112 genomes belonging to _Shigella sonnei_ [2](#references)

   Link to compressed file: [dataset #2: _Shigella sonnei_](http://usegalaxy.sorbonne-universite.fr/nextcloud/index.php/s/BGsKRLSLTri5bTd/download)

#### Dataset #3: 390 genomes belonging to _Pseudomonas aeruginosa_ [3](#references)

   Link to compressed file: [dataset #3: _Pseudomonas aeruginosa_](http://usegalaxy.sorbonne-universite.fr/nextcloud/index.php/s/SZpE2TNHtEzrd8c/download)

#### Dataset #4: 641 genomes belonging to _Salmonella enterica_ with different antibiotic resistance patterns [4](#references)

   a) Link to the compressed file from the **NCBI** repository: [dataset #4: _Salmonella enterica_](https://www.ncbi.nlm.nih.gov/assembly?LinkName=bioproject_assembly_all&from_uid=242614)

   b) Using the bash console, extract the genome data and rename it into the working directory:

   ```
   tar -zxvf /download_full_path/genome_assemblies.tar -C /working_dir_full_path/
   mv genome_assemblies Salmonella_enterica
   rm -f genome_assemblies.tar
   ```

   c) Run **sraX** using your own options. The following command, is just an example:

   ```
   sraX -i Salmonella_enterica -id 98 -c 85 -o Salmonella_enterica_AMR_profiles
   ```

#### Dataset #5: 76 genomes belonging to _Escherichia coli_ from farm isolates [5](#references)

   a) Link to the compressed file from the **NCBI** repository: [dataset #5: _Escherichia coli_](https://www.ncbi.nlm.nih.gov/assembly?LinkName=bioproject_assembly_all&from_uid=266657)

   b) Using the bash console, extract the genome data and rename it into the working directory:

   ```
   tar -zxvf /download_full_path/genome_assemblies.tar -C /working_dir_full_path/
   mv genome_assemblies Escherichia_coli
   rm -f genome_assemblies.tar
   ```

   c) Run **sraX** using your own options. The following command, is just an example:

   ```
   sraX -i Escherichia_coli -t 10 -id 85 -c 75 -o Escherichia_coli_AMR_analysis
   ```


## 2) Compilation of an external AMR DB, originated from public repositories or user-provided

### Public ARG sequences repositories:
The following are just examples of additional ARGs that can be provided to the **sraX** analysis, in
order to increase AMR DB volume and its detection range.

   **A)** [ARGDIT](https://github.com/phglab/ARGDIT)
   
   A recently published work [[6]](https://doi.org/10.1093/bioinformatics/bty987) describes the **ARGDIT** toolkit for creating curated AMR DBs. The authors provided already [pre-compiled AMR DBs](https://github.com/phglab/ARGDIT/tree/master/sample_integrated_dbs) as examples, and this valuable information is going to be employed for demonstrating **sraX**'s practicality and utility for resistome profiling.

   The curated ARG data will be downloaded and the headers will be formatted for being effective for **sraX** analysis. Using the bash console, run the following commands:
   
   ```
   wget -O User_AMR_DB/Public_repositories/argdit_dna.fa https://github.com/phglab/ARGDIT/blob/master/sample_integrated_dbs/argdit_nt_db.fa?raw=true

   awk -F \| '/^>/ { print ">"$2"|"$1"|"$3"|protein_homolog|"$9"|"$5; next } 1' User_AMR_DB/Public_repositories/argdit_dna.fa > User_AMR_DB/Public_repositories/argdit_dna_formatted.fa
   
   sed -i 's/|>/|/g' User_AMR_DB/Public_repositories/argdit_dna_formatted.fa
   
   rm -f User_AMR_DB/Public_repositories/argdit_dna.fa
   ```
   
   **B)** [NCBI Bacterial Antimicrobial Resistance Reference Gene Database](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA313047)
   
   The NCBI public repository is comprised by annotated DNA sequences that encode proteins conferring AMR, and it constitutes an aggregation of collections from multiple sources which were previously curated and further expanded by reviewing the dedicated literature.
   
  Using the bash console, run the following commands:
  
   ```
   wget -O User_AMR_DB/Public_repositories/ncbi_aa.fa ftp://ftp.ncbi.nlm.nih.gov/pathogen/Antimicrobial_resistance/AMRFinder/data/latest/AMRProt
   
   awk -F \| '/^>/ { print ">"$6"|"$2"|"$9"|protein_homolog|"$8"|Not_indicated"; next } 1' User_AMR_DB/Public_repositories/ncbi_aa.fa > User_AMR_DB/Public_repositories/ncbi_aa_formatted.fa
   
   rm -f User_AMR_DB/Public_repositories/ncbi_aa.fa
   ```
#### Incorporating the previously compiled external AMR DB to the **sraX** analysis:
Employing any of acquired genome datasets we can perform its resistome profiling by adding extra ARG sequences.

   a) Under deafult options:

   ```
   sraX -i Enterococcus_spp -u User_AMR_DB/Public_repositories/argdit_dna_formatted.fa

   sraX -i Enterococcus_spp -u User_AMR_DB/Public_repositories/ncbi_aa_formatted.fa
   ```
   
   We also can concatenate several AMR DBs into a single file, as a new AMR DB:

   ```
   cat User_AMR_DB/Public_repositories/argdit_dna_formatted.fa User_AMR_DB/Public_repositories/ncbi_aa_formatted.fa > User_AMR_DB/Public_repositories/cat_amrdb.fa

   sraX -i Enterococcus_spp -u User_AMR_DB/Public_repositories/cat_amrdb.fa
   ```

   a) Under defined options:

   ```
   sraX -i Enterococcus_spp -u User_AMR_DB/Public_repositories/argdit_dna_formatted.fa -id 95 -c 98

   sraX -i Enterococcus_spp -u User_AMR_DB/Public_repositories/ncbi_aa_formatted.fa -id 80 -c 80
   ```

## References.

[1] Tyson GH _et al._ (2018). [Whole-genome sequencing based characterization of antimicrobial resistance in _Enterococcus_](https://doi.org/10.1093/femspd/fty018), Pathogens and Disease, Volume 76, Issue 2.

[2] Holt KE _et al._ (2012). [_Shigella sonnei_ genome sequencing and phylogenetic analysis indicate recent global dissemination from Europe](http://www.nature.com/doifinder/10.1038/ng.2369), _Nat. Genet._ 44(9): 1056-1059. 

[3] Kos VN _et al._ (2015). [The resistome of _Pseudomonas aeruginosa_ in relationship to phenotypic susceptibility](http://dx.doi.org/10.1128/AAC.03954-14), _Antimicrob Agents Chemother_ 59:427– 436.

[4] Tyson GH _et al._ (2015). [WGS accurately predicts antimicrobial resistance in _Escherichia coli_](https://doi.org/10.1128/AAC.01030-16), _J. Antimicrob. Chemother._, 70(10):2763-9.

[5] McDermott PF _et al._ (2016). [Whole-genome sequencing for detecting antimicrobial resistance in nontyphoidal _Salmonella_](https://academic.oup.com/jac/article/70/10/2763/830949),  _Antimicrob. Agents Chemother._, 60(9):5515–20.

[6] Jimmy Ka Ho Chiu, Rick Twee-Hee Ong; ARGDIT: a validation and integration toolkit for Antimicrobial Resistance Gene Databases, _Bioinformatics_, , bty987, 
