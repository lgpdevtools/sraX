# sraX User Guide: real data examples

## 1) User-provided data for AMR DB compilation
### Public ARG sequences repositories:
   **A)** [ARGDIT's pre-compiled AMR DB](https://github.com/phglab/ARGDIT/tree/master/sample_integrated_dbs)
   
   A recently published work [[1]](https://doi.org/10.1093/bioinformatics/bty987) describes a toolkit ([ARGDIT](https://github.com/phglab/ARGDIT)) for creating curated AMR DBs. The authors provided already integrated AMR DBs as examples, and this valuable information is going to be employed for demonstrating **sraX**'s practicality and utility for resistome profiling.

   A) **ARGDIT**'s curated AMR DB will be downloaded and the headers will be formatted for being effective for **sraX** analysis. Using the bash console, run the following commands:
   ```
   wget -O User_provided_ARGs/Public_repositories/argdit_dna.fa https://github.com/phglab/ARGDIT/blob/master/sample_integrated_dbs/argdit_nt_db.fa?raw=true

   awk -F \| '/^>/ { print ">"$2"|"$1"|"$3"|protein_homolog|"$9"|"$5; next } 1' User_provided_ARGs/Public_repositories/argdit_dna.fa > User_provided_ARGs/Public_repositories/argdit_dna_formatted.fa
   
   sed -i 's/|>/|/g' User_provided_ARGs/Public_repositories/argdit_dna_formatted.fa
   ```

### User's own ARG sequences:

## 2) Genome data acquisition from already analyzed collections

### Data-set 1: 52 genomes belonging to _Escherichia coli_ [[2]](https://doi.org/10.1093/jac/dkw511)
The authors look at antibiotic resistant commensal strains from _E. coli_.

   A) Go to the following **NCBI** repository and download all the genome assemblies: [[data-set-1]](https://www.ncbi.nlm.nih.gov/assembly?LinkName=bioproject_assembly_all&from_uid=335932)   
   
   __Note__ The following steps are recurrent and should be followed for performing the **sraX** analysis with alternative genome data-sets. For analyzing other data, the main modifications are the repository hyperlink (**[data-set-1]**) and the renamed genome directory (**ds1**).
   
   B) Move the compressed downloaded file to the working directory and, using the bash console, extract the genome data and rename the directory:

   ```
   mv /download_full_path/genome_assemblies.tar /working_dir_full_path/
   tar -zxf genome_assemblies.tar
   rm -f genome_assemblies.tar
   mv genome_assemblies ds1
   ```
   C) Run **sraX** using the desired options. The following one is just an example using default options:
   ```
   sraX -d ds1
   ```
   
   D) Adding user-provided ARG sequences:
   ```
   sraX -d ds1 -u User_provided_DB/argdit_dna_formatted.fa
   ```
   
   E) Modifying the amino-acid identity percentage and alignment coverage for detecting positive hits:
   ```
   sraX -d ds1 -u User_provided_DB/argdit_dna_formatted.fa -i 95 -c 95
   ```
   F) Modifying the output result directory:
   ```
   sraX -d ds1 -u User_provided_DB/argdit_dna_formatted.fa -i 75 -c 90 -o ds1_another_test
   ```   
   
### Data-set 2: 76 genomes belonging to _Escherichia coli_ [[3]](https://academic.oup.com/jac/article/70/10/2763/830949)
The authors studied the multidrug-resistant _E. coli_ from farm isolates and identified the specific genetic determinants contributing to AMR.

   A) Go to the following **NCBI** repository and download all the genome assemblies: [[data-set-2]](https://www.ncbi.nlm.nih.gov/assembly?LinkName=bioproject_assembly_all&from_uid=266657)

   B) Follow previous procedures and only change the genome directory name:
   ```
    mv genome_assemblies ds2
   ```
   C) Run **sraX** using your own options. The following one is just an example:
   ```
   sraX -d ds2 -u User_provided_DB/argdit_dna_formatted.fa    
   ```

### Data-set 3: 641 genomes belonging to _Salmonella enterica spp_ [[4]](https://doi.org/10.1128/AAC.01030-16)

The authors look at the phenotype and genotype correlation in _Salmonella enterica_ with different antibiotic resistance patterns.

   A) Go to the following **NCBI** repository and download all the genome assemblies: [[data-set-3]](https://www.ncbi.nlm.nih.gov/assembly?LinkName=bioproject_assembly_all&from_uid=242614)

   B) Follow previous procedures and only change the genome directory name:
   ```
    mv genome_assemblies ds3
   ```
   C) Run **sraX** using your own options. The following one is just an example:
   ```
   sraX -d ds3 -u User_provided_DB/argdit_dna_formatted.fa
   ```


## References.
[1] Jimmy Ka Ho Chiu, Rick Twee-Hee Ong; ARGDIT: a validation and integration toolkit for Antimicrobial Resistance Gene Databases, _Bioinformatics_, , bty987, 

[2] Moran RA, Anantham S, Holt KE, Hall RM. (2017). Prediction of antibiotic resistance from antibiotic resistance genes detected in antibioticresistant commensal _Escherichia coli_ using PCR or WGS. _J Antimicrob. Chemother._, 72:700 –704. .

[3] Tyson GH _et al._ (2015). WGS accurately predicts antimicrobial resistance in _Escherichia coli_., _J. Antimicrob. Chemother._, 70(10):2763-9.

[4] McDermott PF _et al._ (2016). Whole-genome sequencing for detecting antimicrobial resistance in nontyphoidal _Salmonella_. _Antimicrob. Agents Chemother._, 60(9):5515–20.
