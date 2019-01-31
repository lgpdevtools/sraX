#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
program="sraX"
version="v2"
abs_path_dir="/usr/local/bin/${program}"
install_sraX_v=https://raw.githubusercontent.com/lgpdevtools/sraX/master/install_srax.sh
shell_update(){
    srax_flag "clear"
    echo "Check updates for shell..."
    github_v=`wget --no-check-certificate -qO- ${install_sraX_v} | sed -n '/'^version'/p' | cut -d\" -f2`
    if [ ! -z ${github_v} ]; then
        if [[ "${version}" != "${github_v}" ]];then
            echo -e "${COLOR_GREEN}Found a new version, update now!${COLOR_END}"
            echo
            echo -n "Update shell ..."
            if ! wget --no-check-certificate -qO $0 ${install_sraX_v}; then
                echo -e " [${COLOR_RED}failed${COLOR_END}]"
                echo
                exit 1
            else
                echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
                echo
                echo -e "${COLOR_GREEN}Please Re-run${COLOR_END} ${COLOR_PINK}$0 ${clang_action}${COLOR_END}"
                echo
                exit 1
            fi
            exit 1
        fi
    fi
}
srax_flag(){
    local clear_flag=""
    clear_flag=$1
    if [[ ${clear_flag} == "clear" ]]; then
        clear
    fi
    echo ""
    echo "+--------------------------------------------------------------+"
    echo "||       sraX, Written by Leonardo G. Panunzi                 ||"
    echo "||    A tool to install, uninstall or update sraX on Linux    ||"
    echo "||   Code repository:  https://github.com/lgpdevtools/sraX    ||"
    echo "+--------------------------------------------------------------+"
    echo ""
}
set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
    COLOR_END='\E[0m'
}
chk_root(){
    if [[ $EUID -ne 0 ]]; then
        srax_flag
        echo "Error: This script must be run as root!" 1>&2
        exit 1
    fi
}
get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
chk_OS(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}
get_v(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}
centos_v(){
    local code=$1
    local version="`get_v`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi
}
chk_bit(){
    ARCHS=""
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
        ARCHS="amd64"
    else
        Is_64bit='n'
        ARCHS="386"
    fi
}
chk_centos_version(){
if centos_v 5; then
    echo "Not support CentOS 5.x, please change to CentOS 6,7 or Debian or Ubuntu and try again."
    exit 1
fi
}
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

function set_path {
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

function chk_path {
    local dname="${1}"
    local dpath=""

    dpath="$(which "${dname}" 2> /dev/null | tail -n1 | tr -d '\t')"

    if [ -z "${dpath}" ]
    then
        dpath=$(set_path "${dname}")
    else
        if [ -e "${dpath}" -a -x "${dpath}" ]
        then
            echo 1>&2
            read -p "'${dname}' is located in ${dpath}. Is it true? [Y/n] " -n 1
            if [[ ${REPLY} =~ ^[Nn]$ ]]
            then
                dpath="$(set_path "${dname}")"
            fi
        else
            dpath="$(set_path "${dname}")"
        fi
    fi

    echo "${dpath}"
}

function set_R_pckg {
    while :
    do
        local R_pckg_d=""
        echo 1>&2
        read -p "At least one R package (ggplot2, gridExtra, dplyr) to run this pipeline is not found. Are the packages already installed? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            echo 1>&2
            read -p "Please enter the directory for R packages (e.g. /home/dir_name/r_packages): " R_pckg_d
            [ $(chk_R_pckg "${R_pckg_d}") -eq 0 ] && break
        else
            break
        fi
    done

    echo "${R_pckg_d}"
}

function chk_R_pckg {
    local R_pckg_d="${1}"

    if [ -z "${R_pckg_d}" ]
    then
        "${abs_path_dir}/sraXbin/R" --vanilla --slave <<R_SCRIPT
if (all(c("ggplot2", "gridExtra", "dplyr") %in% rownames(installed.packages()))) {
    quit(save="no", status=0)
} else {
    quit(save="no", status=1)
}
R_SCRIPT
    else
        "${abs_path_dir}/sraXbin/R" --vanilla --slave <<R_SCRIPT
if (all(c("ggplot2", "gridExtra", "dplyr") %in% rownames(installed.packages(lib.loc="${R_pckg_d}")))) {
    quit(save="no", status=0)
} else {
    quit(save="no", status=1)
}
R_SCRIPT
    fi
    echo $?
}


install_depend(){
    echo -e "Check dependences setting, please wait..."
    if [ -d ${abs_path_dir} ]
	then
    	rm -r ${abs_path_dir}
    	mkdir -p ${abs_path_dir}/sraXbin
    else
	mkdir -p ${abs_path_dir}/sraXbin
    fi

    DIAMOND="$(chk_path "diamond")"
    if [ -z "$DIAMOND" ]
    then
    echo -e "\nDownloading and installing DIAMOND"
    wget http://github.com/bbuchfink/diamond/releases/download/v0.9.22/diamond-linux64.tar.gz
    tar xvfz diamond-linux64.tar.gz -C "${abs_path_dir}/sraXbin"
    rm -f diamond-linux64.tar.gz
    rm -f ${abs_path_dir}/sraXbin/LICENSE
    rm -f ${abs_path_dir}/sraXbin/diamond_manual.pdf
    chmod a+x ${abs_path_dir}/sraXbin/diamond
    fi
    
    MUSCLE="$(chk_path "muscle")"
    if [ -z "$MUSCLE" ]
    then
    echo -e "\nDownloading and installing MUSCLE"
    wget http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
    tar xvfz muscle3.8.31_i86linux64.tar.gz -C "${abs_path_dir}/sraXbin"
    rm -f muscle3.8.31_i86linux64.tar.gz
    mv ${abs_path_dir}/sraXbin/muscle3.8.31_i86linux64 ${abs_path_dir}/sraXbin/muscle
    chmod a+x ${abs_path_dir}/sraXbin/muscle3.8.31_i86linux64
    fi
    
    NCBI_BX="$(chk_path "blastx")"
    BLAST_V="2.8.1"
    if [ -z "$NCBI_BX" ]
    then
    echo -e "\nDownloading and installing BLAST+ executables"
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-${BLAST_V}+-x64-linux.tar.gz
    tar xvfz ncbi-blast-${BLAST_V}+-x64-linux.tar.gz -C "${abs_path_dir}/sraXbin"
    rm -f ncbi-blast-${BLAST_V}+-x64-linux.tar.gz
    chmod -R a+x ${abs_path_dir}/sraXbin/ncbi-blast-${BLAST_V}+/sraXbin/
    cp ${abs_path_dir}/sraXbin/ncbi-blast-${BLAST_V}+/sraXbin/* ${abs_path_dir}/sraXbin/
    rm -r ${abs_path_dir}/sraXbin/ncbi-blast-${BLAST_V}+
    fi

    R="$(chk_path "R")"
    if [ -z "$R" ]
    then
    echo -e "\nDownloading and installing R"
    apt-get -y install r-base libapparmor1 libcurl4-gnutls-dev libxml2-dev libssl-dev gdebi-core
    apt-get install libcairo2-dev
    apt-get install libxt-dev
    apt-get install git-core
    sudo su - -c "R -e \"install.packages('ggplot2', repos='http://cran.rstudio.com/')\""
    sudo su - -c "R -e \"install.packages('gridExtra', repos='http://cran.rstudio.com/')\""
    sudo su - -c "R -e \"install.packages('dplyr', repos='http://cran.rstudio.com/')\""
    else
    ln -sf "$R" "${abs_path_dir}/sraXbin/R"
    fi

    if [ $(chk_R_pckg) -eq 1 ]
    then
    R_pckg_d="$(set_R_pckg)"
    if [ -z "${R_pckg_d}" ]
    then
        echo 1>&2
        read -p "Do you want to install the packages by this script? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
        sudo su - -c "R -e \"install.packages('ggplot2', repos='http://cran.rstudio.com/')\""
        sudo su - -c "R -e \"install.packages('gridExtra', repos='http://cran.rstudio.com/')\""
        sudo su - -c "R -e \"install.packages('dplyr', repos='http://cran.rstudio.com/')\""
        else
            R_pckg_d=""
            errs=$(($errs+1))
        fi
      fi
    fi
}
install_srax(){
    srax_flag
    echo -e "Installing sraX and its dependences..."
    disable_selinux
    if [ -s ${abs_path_dir}/${program} ] && [ -x ${abs_path_dir}/${program} ] && [ -d ${abs_path_dir}/sraXli ]; then
        echo "${program} is installed!"
    else
        clear

	echo "Setup of sraX running environment"
        echo ""
        echo "============== Check your input =============="
        echo -e "sraX install directory      : ${COLOR_GREEN}${abs_path_dir}${COLOR_END}"
        echo -e "Install log file            : ${COLOR_GREEN}${strPath}/${program}_install.log}${COLOR_END}"
        echo "=============================================="
        echo ""
        echo "Press any key to start...or Press Ctrl+c to cancel"

	char=`get_char`
	install_depend
	mv ${strPath}/${program} ${abs_path_dir}/${program}
	mv ${strPath}/sraXlib ${abs_path_dir}
	
	chown root:root -R ${abs_path_dir}

    	if [ -s ${abs_path_dir}/${program} ]; then
        [ ! -x ${abs_path_dir}/${program} ] && chmod 755 ${abs_path_dir}/${program}
	ln -sf "${abs_path_dir}/${program}" "/usr/bin/${program}"
	ln -sf "${abs_path_dir}/sraXbin" "/usr/bin/"
    	else
        echo -e " ${COLOR_RED}failed${COLOR_END}"
        exit 1
    	fi
	
	echo ""
    	echo "Congratulations, ${program_name} install completed!"

    fi
}
    
############################### uninstall ##################################
uninstall_srax(){
    srax_flag
    if [ -s ${program_init} ] || [ -s ${abs_path_dir}/${program} ] ; then
        echo "============== Uninstall ${program} =============="
        str_uninstall="n"
        echo -n -e "${COLOR_YELOW}You want to uninstall?${COLOR_END}"
        read -p "[y/N]:" str_uninstall
        case "${str_uninstall}" in
        [yY]|[yY][eE][sS])
        echo ""
        echo "You select [Yes], press any key to continue."
        str_uninstall="y"
        char=`get_char`
        ;;
        *)
        echo ""
        str_uninstall="n"
        esac
        if [ "${str_uninstall}" == 'n' ]; then
            echo "You select [No], shell exit!"
        else
            rm -fr ${abs_path_dir}
            rm -fr /usr/bin/${program}*
	    echo "${program} uninstall success!"
        fi
    else
        echo "${program} Not install!"
    fi
    exit 0
}
############################### update ##################################
update_srax(){
    srax_flag "clear"
    if [ -s ${abs_path_dir}/${program} ] ; then
    echo "============== Update ${program} =============="
    chk_OS
    chk_centos_version
    chk_bit
    get_v
    echo "Check updates for sraX..."
    # github_v=`wget --no-check-certificate -qO- ${install_sraX_v} | sed -n '/'^version'/p' | cut -d\" -f2`
    github_v=`wget --no-check-certificate -qO- ${install_sraX_v} | sed -n '/'^errs'/p' | cut -d\" -f2`
    local_sraX_v=`${abs_path_dir}/${program} --version`
    echo -e "${COLOR_GREEN}${program}  local version ${local_sraX_v}${COLOR_END}"
    echo -e "${COLOR_GREEN}${program} GitHub version ${github_v}${COLOR_END}"
    if [ ! -z ${github_v} ]; then
        if [[ "${version}" != "${github_v}" ]];then
	# if [[ "${local_sraX_v}" != "${github_v}" ]];then
            echo
	    echo -e "${COLOR_GREEN}Found a new version, update now!${COLOR_END}"
            echo
            echo -n "Update sraX ..."
            if ! wget --no-check-certificate -qO $0 ${install_sraX_v}; then
                echo -e " [${COLOR_RED}failed${COLOR_END}]"
                echo
                exit 1
            else
                echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
                echo
		  if [ -d ${strPath}/${program}_cloned ];then
        	  rm -r ${strPath}/${program}_cloned
		  rm -r ${strPath}/${program}lib
		  rm -r ${strPath}/${program}
	  	  fi
			if ! git clone https://github.com/lgpdevtools/sraX.git ${program}_cloned; then
                    	echo "Failed to clone the ${program} GitHub repository!"
                    	exit 1
                	else
                    	mv ${strPath}/${program}_cloned/${program}* ${strPath}/
			echo
			echo -e "${COLOR_GREEN}${program_init}sraX new version and updated scripts were successfully downloaded !${COLOR_END}"
                	[ ! -x ${program} ] && chmod 755 ${program}
			echo "${program} version `${strPath}/${program} --version`"
            		echo "${program} update success!"
			fi
		echo
                echo -e "${COLOR_GREEN}To complete sraX update, please re-run${COLOR_END} ${COLOR_PINK}$0 install${clang_action}${COLOR_END}"
		rm -r /usr/bin/${program}* ${abs_path_dir}
                echo
                exit 1
            fi
            exit 1
        else
        echo -e "no need to update !!!${COLOR_END}"
        fi
    fi

  else
  echo "${program} Not install!"
  fi
  exit 0
}

clear
strPath=`pwd`
chk_root
set_text_color
chk_OS
chk_centos_version
chk_bit
action=$1
[  -z $1 ]
case "$action" in
install)
    [ -e "${strPath}/${program}_install.log" ] && rm -f "/${program}_install.log"
    touch "${strPath}/${program}_install.log"
    install_srax 2>&1 | tee ${strPath}/${program}_install.log
    ;;
uninstall)
    [ -e "${strPath}/${program}_uninstall.log" ] && rm -f "/${program}_uninstall.log"
    touch "${strPath}/${program}_uninstall.log"
    uninstall_srax 2>&1 | tee ${strPath}/${program}_uninstall.log
    ;;
update)
    [ -e "${strPath}/${program}_update.log" ] && rm -f "/${program}_update.log"
    touch "${strPath}/${program}_update.log"
    update_srax 2>&1 | tee ${strPath}/${program}_update.log
    ;;
*)
    srax_flag
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install | uninstall | update}"
    RET_VAL=1
    ;;
esac
