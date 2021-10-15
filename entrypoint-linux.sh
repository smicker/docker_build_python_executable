#!/bin/bash

# This script will pip install every package included in requirements.txt or
# included in another specified requirements file. Then it will run pyinstaller
# to compile a python program into an exe file.
# Without arguments it will do pip install on ./requirements.txt and run
# pyinstaller --clean -y --dist ./dist/windows --workpath /tmp *.spec
# Specify other pip req file with -p <file> or --pip_req <file>.
# Specify other pyinstaller command by "pyinstaller <custom args>"

# Fail on errors.
set -e

# Make sure .bashrc is sourced
. /root/.bashrc

OTHER_COMMAND=()
PIP_REQUIREMENTS_FILE="requirements.txt"
OUT_FOLDER=""

# Parses the value of the --distpath or --dist key if they are present in the input string.
# Shall be called like: return_value=$(parse_dist_folder <mystring>)
# Input: A string, for example "pyinstaller --dist ./dist/windows -w file.py"
# Returns: The value of the --dist or --distpath key, like "./dist/windows" for the example
#          above. If the value is surrounded by "" or '', those "" and '' will be stripped
#          from the returned value. If --dist or --distpath is not found this will return
#          the empty string "".
function parse_dist_folder() {
    local tmp_str=$1

    if [[ "${arg}" != *"--dist "* ]] && [[ "${arg}" != *"--distpath "* ]]; then
	# Key is not found
	echo ""
	return 0
    fi	

    # Both dist and distpath can be used so handle both of them.
    # Remove everything before "--distpath " or "--dist "
    tmp_str=${tmp_str#*--distpath }
    tmp_str=${tmp_str#*--dist }

    # Handle if value is surrounded by " or ' which could be the case if folder contains spaces
    if [[ ${tmp_str:0:1} == "\"" ]]; then
	tmp_str=${tmp_str:1} 
        tmp_str=${tmp_str%%\"*}
    elif [[ ${tmp_str:0:1} == "'" ]]; then
	tmp_str=${tmp_str:1} 
        tmp_str=${tmp_str%%\'*}
    else
        tmp_str=${tmp_str%% *}
    fi
    echo "${tmp_str}"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
	-p|--pip_req)
	    PIP_REQUIREMENTS_FILE=$2
	    shift # past argument
	    shift # past value
	    ;;
	*)
	    OTHER_COMMAND+=("$arg")
            if [[ "$arg" =~ "pyinstaller" ]]; then
                tmp_return=$(parse_dist_folder "$arg")
		if [[ ${tmp_return} ]]; then
		    OUT_FOLDER=${tmp_return}
		else
	            # dist folder not set, use default.
	            OUT_FOLDER="./dist"
		fi
            fi
	    shift
	    ;;
    esac
done

# Allow the workdir to be set using an env var.
# Useful for CI pipiles which use docker for their build steps
# and don't allow that much flexibility to mount volumes
WORKDIR=${SRCDIR:-/src}

#
# In case the user specified a custom URL for PYPI, then use
# that one, instead of the default one.
#
if [[ "$PYPI_URL" != "https://pypi.python.org/" ]] || \
   [[ "$PYPI_INDEX_URL" != "https://pypi.python.org/simple" ]]; then
    # the funky looking regexp just extracts the hostname, excluding port
    # to be used as a trusted-host.
    mkdir -p /root/.pip
    echo "[global]" > /root/.pip/pip.conf
    echo "index = $PYPI_URL" >> /root/.pip/pip.conf
    echo "index-url = $PYPI_INDEX_URL" >> /root/.pip/pip.conf
    echo "trusted-host = $(echo $PYPI_URL | perl -pe 's|^.*?://(.*?)(:.*?)?/.*$|$1|')" >> /root/.pip/pip.conf

    echo "Using custom pip.conf: "
    cat /root/.pip/pip.conf
fi

cd $WORKDIR

# Handle pip install
if [ -f $PIP_REQUIREMENTS_FILE ]; then
    echo "Executing: pip3 install -r $PIP_REQUIREMENTS_FILE"
    pip3 install -r $PIP_REQUIREMENTS_FILE
else
    echo "Warning, pip requirements file $PIP_REQUIREMENTS_FILE is not found, ignoring!!"
fi # [ -f $PIP_REQUIREMENTS_FILE ]

# Handle pyinstaller
if [[ "$OTHER_COMMAND" == "" ]]; then
    DEFAULT_COMMAND="pyinstaller --clean -y --dist ./dist/linux --workpath /tmp *.spec"
    echo "Executing default command: $DEFAULT_COMMAND"
    sh -c "$DEFAULT_COMMAND"
    OUT_FOLDER="./dist/linux"
else
    echo "Executing custom command: ${OTHER_COMMAND[*]}"
    sh -c "${OTHER_COMMAND[*]}"
fi # [[ "$OTHER_COMMAND" == "" ]]

if [[ ${OUT_FOLDER} ]]; then
    echo "Executing: chown -R --reference=. \"${OUT_FOLDER}\""
    chown -R --reference=. "${OUT_FOLDER}"
fi
