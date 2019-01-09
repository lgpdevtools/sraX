#!/usr/bin/env bash

errs=0

function set_dpath {
    local dname="${1}"

    while :
    do
        local dpath=""
        echo 1>&2
        read -p "${dname} is not found. Is the program already installed? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            echo 1>&2
            read -p "Please enter the path of ${dname} program (e.g. /home/dir_name/bin/${dname}): " dpath
            [ -e "${dpath}" -a -x "${dpath}" ] && break
        else
            break
        fi
    done

    echo "${dpath}"
}

function set_rpkg {
    while :
    do
        local rpkg_dir=""
        echo 1>&2
        read -p "At least one R package (ggplot2, gridExtra, dplyr) to run this pipeline is not found. Are the packages already installed? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            echo 1>&2
            read -p "Please enter the directory for R packages (e.g. /home/dir_name/r_packages): " rpkg_dir
            [ $(check_rpkg "${rpkg_dir}") -eq 0 ] && break
        else
            break
        fi
    done

    echo "${rpkg_dir}"
}

function check_dpath {
    local dname="${1}"
    local dpath=""
   
    dpath="$(which "${dname}" 2> /dev/null | tail -n1 | tr -d '\t')"

    if [ -z "${dpath}" ]
    then
        dpath=$(set_dpath "${dname}")
    else
        if [ -e "${dpath}" -a -x "${dpath}" ]
        then
            echo 1>&2
            read -p "'${dname}' is located in ${dpath}. Is it true? [Y/n] " -n 1
            if [[ ${REPLY} =~ ^[Nn]$ ]]
            then
                dpath="$(set_dpath "${dname}")"
            fi
        else
            dpath="$(set_dpath "${dname}")"
        fi
    fi

    echo "${dpath}"
}


function check_rpkg {
    local rpkg_dir="${1}"

    if [ -z "${rpkg_dir}" ]
    then
        "${sraX_DIR}/bin/R" --vanilla --slave <<R_SCRIPT
if (all(c("ggplot2", "gridExtra", "dplyr") %in% rownames(installed.packages()))) {
    quit(save="no", status=0)
} else {
    quit(save="no", status=1)
}
R_SCRIPT
    else
        "${sraX_DIR}/bin/R" --vanilla --slave <<R_SCRIPT
if (all(c("ggplot2", "gridExtra", "dplyr") %in% rownames(installed.packages(lib.loc="${rpkg_dir}")))) {
    quit(save="no", status=0)
} else {
    quit(save="no", status=1)
}
R_SCRIPT
    fi
    echo $?
}

#----------- Set bin directory
sraX_DIR=$(cd "$(dirname "$0")" && pwd)

BASH_PATH="$(which bash 2> /dev/null | tail -n1 | tr -d '\t')"

echo "Installing sraX and its dependences..."

if [ -d $sraX_DIR/bin ]
then
    rm -r $sraX_DIR/bin
    mkdir $sraX_DIR/bin
else
mkdir $sraX_DIR/bin
fi

[ -e "${sraX_DIR}/bin/srax_install.log" ] && rm -f "${sraX_DIR}/bin/srax_install.log"
touch "${sraX_DIR}/bin/srax_install.log"

#----------- Check dependences
echo "These are the full paths of the required dependencies for running 'sraX':" >> "${sraX_DIR}/bin/srax_install.log"
echo "" >> "${sraX_DIR}/bin/srax_install.log"

DIAMOND="$(check_dpath "diamond")"
if [ -z "$DIAMOND" ]
then
    echo -e "\nDownloading and installing DIAMOND"
    wget http://github.com/bbuchfink/diamond/releases/download/v0.9.22/diamond-linux64.tar.gz	
    tar xvfz diamond-linux64.tar.gz -C "${sraX_DIR}/bin"
    rm -f diamond-linux64.tar.gz
    rm -f ${sraX_DIR}/bin/LICENSE
    rm -f ${sraX_DIR}/bin/diamond_manual.pdf
    chmod a+x ${sraX_DIR}/bin/diamond
    echo "DIAMOND = '${sraX_DIR}/bin/diamond'" >> "${sraX_DIR}/bin/srax_install.log"
else
    ln -sf "$DIAMOND" "${sraX_DIR}/bin/diamond"
    echo "DIAMOND = '$DIAMOND'" >> "${sraX_DIR}/bin/srax_install.log"
fi

NCBI_BX="$(check_dpath "blastx")"
BLAST_V="2.8.1"
if [ -z "$NCBI_BX" ]
then
    echo -e "\nDownloading and installing BLAST+ executables"
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-${BLAST_V}+-x64-linux.tar.gz
    tar xvfz ncbi-blast-${BLAST_V}+-x64-linux.tar.gz -C "${sraX_DIR}/bin"
    rm -f ncbi-blast-${BLAST_V}+-x64-linux.tar.gz
    chmod -R a+x ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+/bin/
    cp ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+/bin/* ${sraX_DIR}/bin/
    rm -r ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+
    echo "BLASTX (Version: ${BLAST_V}) = '${sraX_DIR}/bin/blastx'" >> "${sraX_DIR}/bin/srax_install.log"
else
    ln -sf "$NCBI_BX" "${sraX_DIR}/bin/"
    echo "BLASTX (Version: ${BLAST_V}) = '$NCBI_BX'" >> "${sraX_DIR}/bin/srax_install.log"
fi

NCBI_BN="$(check_dpath "blastn")"
BLAST_V="2.8.1"
if [ -z "$NCBI_BN" ] 
then
    echo -e "\nDownloading and installing BLAST+ executables"
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-${BLAST_V}+-x64-linux.tar.gz
    tar xvfz ncbi-blast-${BLAST_V}+-x64-linux.tar.gz -C "${sraX_DIR}/bin"
    rm -f ncbi-blast-${BLAST_V}+-x64-linux.tar.gz
    chmod -R a+x ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+/bin/
    cp ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+/bin/* ${sraX_DIR}/bin/
    rm -r ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+
    echo "BLASTN (Version: ${BLAST_V}) = '${sraX_DIR}/bin/blastn'" >> "${sraX_DIR}/bin/srax_install.log"
else
    ln -sf "$NCBI_BN" "${sraX_DIR}/bin/"
    echo "BLASTN (Version: ${BLAST_V}) = '$NCBI_BN'" >> "${sraX_DIR}/bin/srax_install.log"
fi

NCBI_MB="$(check_dpath "makeblastdb")"
BLAST_V="2.8.1"
if [ -z "$NCBI_MB" ] 
then
    echo -e "\nDownloading and installing BLAST+ executables"
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-${BLAST_V}+-x64-linux.tar.gz
    tar xvfz ncbi-blast-${BLAST_V}+-x64-linux.tar.gz -C "${sraX_DIR}/bin"
    rm -f ncbi-blast-${BLAST_V}+-x64-linux.tar.gz
    chmod -R a+x ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+/bin/
    cp ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+/bin/* ${sraX_DIR}/bin/
    rm -r ${sraX_DIR}/bin/ncbi-blast-${BLAST_V}+
    echo "MAKEBLASTDB (Version: ${BLAST_V}) = '${sraX_DIR}/bin/makeblastdb'" >> "${sraX_DIR}/bin/srax_install.log"
else
    ln -sf "$NCBI_MB" "${sraX_DIR}/bin/"
    echo "MAKEBLASTDB (Version: ${BLAST_V}) = '$NCBI_MB'" >> "${sraX_DIR}/bin/srax_install.log"
fi


MUSCLE="$(check_dpath "muscle")"
if [ -z "$MUSCLE" ]
then
    echo -e "\nDownloading and installing MUSCLE"
    wget http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
    tar xvfz muscle3.8.31_i86linux64.tar.gz -C "${sraX_DIR}/bin"
    rm -f muscle3.8.31_i86linux64.tar.gz
    chmod a+x ${sraX_DIR}/bin/muscle3.8.31_i86linux64
    mv ${sraX_DIR}/bin/muscle3.8.31_i86linux64 ${sraX_DIR}/bin/muscle
    echo "MUSCLE = '${sraX_DIR}/bin/muscle'" >> "${sraX_DIR}/bin/srax_install.log"
else
    ln -sf "$MUSCLE" "${sraX_DIR}/bin/muscle"
    echo "MUSCLE = '$MUSCLE'" >> "${sraX_DIR}/bin/srax_install.log"
fi

R="$(check_dpath "R")"
if [ -z "$R" ]
then
    echo -e "\nDownloading and installing R"
    sudo apt-get -y install r-base libapparmor1 libcurl4-gnutls-dev libxml2-dev libssl-dev gdebi-core
    sudo apt-get install libcairo2-dev
    sudo apt-get install libxt-dev
    sudo apt-get install git-core
    sudo su - -c "R -e \"install.packages('ggplot2', repos='http://cran.rstudio.com/')\""
    sudo su - -c "R -e \"install.packages('gridExtra', repos='http://cran.rstudio.com/')\""
    sudo su - -c "R -e \"install.packages('dplyr', repos='http://cran.rstudio.com/')\""
    echo "R = '${sraX_DIR}/bin/R'" >> "${sraX_DIR}/bin/srax_install.log"
else
    ln -sf "$R" "${sraX_DIR}/bin/R"
    echo "R = '$R'" >> "${sraX_DIR}/bin/srax_install.log"
fi

if [ $(check_rpkg) -eq 1 ]
then
    rpkg_dir="$(set_rpkg)"
    if [ -z "${rpkg_dir}" ]
    then
        echo 1>&2
        read -p "Do you want to install the packages by this script? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
	    sudo su - -c "R -e \"install.packages('ggplot2', repos='http://cran.rstudio.com/')\""
    	sudo su - -c "R -e \"install.packages('gridExtra', repos='http://cran.rstudio.com/')\""
    	sudo su - -c "R -e \"install.packages('dplyr', repos='http://cran.rstudio.com/')\""
	else
            rpkg_dir=""
	    errs=$(($errs+1))
        fi
    fi
fi

echo

chmod -R a+x ${sraX_DIR}/sraXlib/
chmod a+x ${sraX_DIR}/sraX

	#----------- Check errors
	if  [[ ! -s ${sraX_DIR}/bin/diamond ]] || [[ ! -s ${sraX_DIR}/bin/blastx ]] || [[ ! -s ${sraX_DIR}/bin/blastn ]] || [[ ! -s ${sraX_DIR}/bin/makeblastdb ]] || [[ ! -s ${sraX_DIR}/bin/muscle ]] || [[ ! -s ${sraX_DIR}/bin/R ]]
	then
	errs=$(($errs+1))
	fi
	
	if [  $errs -gt 0 ]
	then
		echo "" >> "${sraX_DIR}/bin/srax_install.log"
        	echo -e "Some dependencies were not properly installed.\nPlease, restart this script." >> "${sraX_DIR}/bin/srax_install.log"
		echo
		echo -e "\nSome errors arose in installing 'sraX'.\nPlease, check the 'srax_install.log' file and restart this script."
		echo
	exit 0
	else
		echo "" >> "${sraX_DIR}/bin/srax_install.log"
		echo "'sraX' and its dependencies were successfully installed." >> "${sraX_DIR}/bin/srax_install.log"
		echo
		echo "Congratulations! ..."
		echo "sraX and its dependencies were successfully installed."
	fi
exit 0
