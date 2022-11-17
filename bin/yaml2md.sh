#!/bin/sh
#
# Purpose {{{
# This script will try to extract Markdown content from yaml file(s)
#   1. Grep content from input file(s) and exclude some patterns.
#   2. Output file will have the form dirname_filename.md.
#   3. If input is a directory, all yml file(s) will be parsed.
#
# v2022-11-17
# }}}
# Vars {{{
PROGNAME=$(basename "${0}"); readonly PROGNAME
PROGDIR=$(readlink -m $(dirname "${0}")); readonly PROGDIR
ARGS="${*}"; readonly ARGS
readonly NBARGS="${#}"
[ -z "${DEBUG}" ] && DEBUG=1
## Export DEBUG for sub-script
export DEBUG

## Default values for some vars
### Regexp to exclude some lines from Yaml file
### Lines starts with "# ..", used as dedicate Yaml comments.
### Lines starts with "---", that signal the start of a Yaml document.
### Lines starts with whitespaces and finish with "# ]]]" used to close vim foldmarkers.
readonly GREP_EXCLUDE_REGEXP_DEFAULT="(^# \.\.|^---|^ * # \]\]\])"
### Destination directory to store Markdown file
DEST_DIR_DEFAULT=$(readlink -m "${PROGDIR}/.."); readonly DEST_DIR_DEFAULT
### Don't ignore empty file/directory by default
IGNORE_EMPTY_DIRECTORY_DEFAULT=1

## Colors
readonly PURPLE='\033[1;35m'
readonly RED='\033[0;31m'
readonly RESET='\033[0m'
readonly COLOR_DEBUG="${PURPLE}"
# }}}
usage() {                                                       # {{{

	cat <<- HELP
usage: $PROGNAME [-d|-i|-h]

Try to extract some Markdown content from Yaml file(s).

EXAMPLES :
    - Extract Markdown from a specific file
        ${PROGNAME} defaults/main.yml

    - Manage all Yaml files of a vars/ directory
        ${PROGNAME} --input-dir vars

    - Try to manage Yaml files of vars/ directory even if it doesn't exists
        ${PROGNAME} --input-dir vars --ignore-empty-directory

OPTIONS :
    -d,--dest,--destination
        Set the destination directory.
        Default: ${DEST_DIR_DEFAULT}

    --debug
        Enable debug messages.

    -i,--input,--input-dir
        Option to specify input Yaml file/directory to process.
        Default: Use first argument.

    --ignore-empty-directory
        Set ignore_empty mode to return a success state even if
        input directory is empty (0= enable; 1= disable).
        Default: ${IGNORE_EMPTY_DIRECTORY_DEFAULT}

    --grep-exclude-regexp
        Set specific pattern to exclude from Yaml file.
        Default : ${GREP_EXCLUDE_REGEXP_DEFAULT}

    -h,--help
        Print this help message.
HELP

}
# }}}
debug_message() {                                               # {{{

	local_debug_message="${1}"

	## Print message if DEBUG is enable (=0)
	[ "${DEBUG}" -eq "0" ] && printf '\e[1;35m%-6b\e[m\n' "DEBUG − ${PROGNAME} : ${local_debug_message}"

	unset local_debug_message

	return 0
}
# }}}
error_message() {                                               # {{{

	local_error_message="${1}"
	local_error_code="${2}"

	## Print message
	printf '%b\n' "ERROR − ${PROGNAME} : ${RED}${local_error_message}${RESET}"

	exit "${local_error_code:=66}"
}
# }}}
define_vars() {                                                 # {{{

	## If input wasn't defined (argument) {{{
	#if [ -z "${input}" ]; then
		#error_message "Expect at least one argument. See informations (--help)." 01
	#fi
	# }}}
	## If input_arg was defined (argument) {{{
	if [ -n "${input_arg}" ]; then
		## Get absolut path to input_arg
		input=$(readlink -m "${input_arg}")
	else
		## Exit with error message
		error_message "Expect at least one argument. See informations (--help)." 01
	fi
	# }}}
	## If grep_exclude_regexp wasn't defined (argument) {{{
	if [ -z "${grep_exclude_regexp}" ]; then
		## Use default value
		readonly grep_exclude_regexp="${GREP_EXCLUDE_REGEXP_DEFAULT}"
	fi
	# }}}
	## If dest_dir_arg was defined (argument) {{{
	if [ -n "${dest_dir_arg}" ]; then
		## Get absolut path
		dest_dir=$(readlink -m "${dest_dir_arg}"); readonly dest_dir
	else
		## Use default value
		dest_dir=$(readlink -m "${DEST_DIR_DEFAULT}"); readonly dest_dir
	fi
	# }}}
	## If ignore_empty_dir wasn't defined (argument) {{{
	if [ -z "${ignore_empty_dir}" ]; then
		## Use default value
		readonly ignore_empty_dir="${IGNORE_EMPTY_DIRECTORY_DEFAULT}"
	fi
	# }}}

	## Define a build directory to store temp files {{{
	BUILDDIR=".tmp/yaml2md"
	# }}}

}
# }}}
is_directory_absent() {                                         # {{{

	local_directory_absent="${1}"

	## Directory doesn't exists by default
	return_is_directory_absent="0"

	debug_message "--- is_directory_absent function BEGIN"

	### Check if the directory exists
	# shellcheck disable=SC2086
	if test -d "${local_directory_absent}"; then
		return_is_directory_absent="1"
		debug_message "| The directory ${RED}${local_directory_absent}${COLOR_DEBUG} exists."
	else
		return_is_directory_absent="0"
		debug_message "| The directory ${RED}${local_directory_absent}${COLOR_DEBUG} doesn't exist."
	fi

	debug_message "--- is_directory_absent function END"

	unset local_directory_absent

	return "${return_is_directory_absent}"
}
# }}}
is_directory_present() {                                        # {{{

	local_directory_present="${1}"

	## Directory doesn't exists by default
	return_is_directory_present="1"

	debug_message "--- is_directory_present function BEGIN"

	### Check if the directory exists
	# shellcheck disable=SC2086
	if test -d "${local_directory_present}"; then
		return_is_directory_present="0"
		debug_message "| The directory ${RED}${local_directory_present}${COLOR_DEBUG} exists."
	else
		return_is_directory_present="1"
		debug_message "| The directory ${RED}${local_directory_present}${COLOR_DEBUG} doesn't exist."
	fi

	debug_message "--- is_directory_present function END"

	unset local_directory_present

	return "${return_is_directory_present}"
}
# }}}
is_file_present() {                                             # {{{

	local_file_present="${1}"

	## file doesn't exists by default
	return_is_file_present="1"

	debug_message "--- is_file_present function BEGIN"

	### Check if the file exists
	# shellcheck disable=SC2086
	if test -f "${local_file_present}"; then
		return_is_file_present="0"
		debug_message "| The file ${RED}${local_file_present}${COLOR_DEBUG} exists."
	else
		return_is_file_present="1"
		debug_message "| The file ${RED}${local_file_present}${COLOR_DEBUG} doesn't exist."
	fi

	debug_message "--- is_file_present function END"

	unset local_file_present

	return "${return_is_file_present}"
}
# }}}
manage_markdown_content() {                                     # {{{

	## Return True by default
	return_manage_markdown_content="0"

	local_input_file="${1}"
	local_output_file="${2}"

	debug_message "--- manage_markdown_content function BEGIN"

	debug_message "| Ensure output file exists and is empty (${RED}${local_output_file}${COLOR_DEBUG})."
	true > "${local_output_file}" || return_manage_markdown_content="11"

	debug_message "| Extract Markdown content from input file (${RED}${local_input_file}${COLOR_DEBUG})."
	grep --extended-regexp --invert-match "${grep_exclude_regexp}" "${local_input_file}" >> "${local_output_file}" 2>/dev/null \
		|| return_manage_markdown_content="12"

	debug_message "| Put default values into code block."
	{
		## "Default value" pattern will be replace to open code block
		sed -i 's/.*Default value.*/\n``` yml/' "${local_output_file}" || return_manage_markdown_content="13"
		### "# ]]]" (closing vim foldmarkers) will be replace to close code block
		sed -i 's/^# \]\]\]/```\n/' "${local_output_file}" || return_manage_markdown_content="14"
	} 2>/dev/null

	debug_message "| Transform 'normal' comments as real Markdown content."
	## Remove "# " from comments lines
	sed -i 's/^# //' "${local_output_file}" 2>/dev/null || return_manage_markdown_content="15"

	debug_message "| Clean the final file."
	{
		## Remove the opening vim foldmarkers
		sed -i 's/ \[\[\[//' "${local_output_file}" || return_manage_markdown_content="16"
		## Remove remaining closing vim foldmarkers
		sed -i 's/#* \]\]\]//' "${local_output_file}" || return_manage_markdown_content="17"
		## Replace two consecutive blank lines by only one
		sed -i ':a; /^\n*$/{ s/\n//; N;  ba};' "${local_output_file}" 2>/dev/null || return_manage_markdown_content="18"
		## Remove extra whitespaces at the end of lines
		sed -i 's/\s\+$//g' "${local_output_file}" || return_manage_markdown_content="19"
	} 2>/dev/null

	debug_message "--- manage_markdown_content function END"

	unset local_input_file
	unset local_output_file

	return "${return_manage_markdown_content}"
}
# }}}

main() {                                                        # {{{

	## If script should not be executed right now {{{
	### Exit
	#is_script_ok \
		#&& exit 0
	## }}}

	## Define all vars
	define_vars

	## Ensure destination directory exists {{{
	#if is_directory_absent "${dest_dir}"; then
	debug_message "--- MAIN \
Create destination directory (${RED}${dest_dir}${COLOR_DEBUG})."
	mkdir --parents -- "${dest_dir}" \
		|| error_message "Error when creating destination directory (${dest_dir})." 21
	#fi
	## }}}

	## If input is a file {{{
	if is_file_present "${input}"; then
		## Input filename without extension (remove .yml|.yaml extension)
		input_file_basename="$(basename "${input}" | sed 's/.yml\|.yaml//')"
		## Generate output_file_name according to input informations (eg. defaults/main.yml will become defaults_main.md)
		output_file_name="$(basename $(dirname ${input}))_${input_file_basename}.md"
		output_file_path="${dest_dir}/${output_file_name}"

		## Build new Markdown file
		manage_markdown_content "${input}" "${output_file_path}" \
			|| error_message "Can't manage Markdown content from input file (${input}) to a new file (${output_file_path}). See error code : ${?}" "${?}"

		## Exit the script with success
		debug_message "--- MAIN script finish with success"
		exit 0
	fi
	## }}}
	## If input is a directory {{{
	if is_directory_present "${input}"; then
		debug_message "-- Manage ${input} directory content BEGIN"
		## Create BUILDDIR temp directory
		debug_message "| Ensure to create BUILD temp directory (${RED}${BUILDDIR}${COLOR_DEBUG})."
		mkdir --parents -- "${BUILDDIR}" \
			|| error_message "Error when creating BUILDDIR directory (${BUILDDIR})." 41
		## Get the list of Yaml files in this directory
		yaml_file_list="${BUILDDIR}/$(basename ${input}).list"
		debug_message "| Store the list of Yaml files to a temp file (${RED}${yaml_file_list}${COLOR_DEBUG})."
		true > "${yaml_file_list}"
		find "${input}" -maxdepth 1 -type f -iname "*.yml" -or -iname "*.yaml" >> "${yaml_file_list}" \
			|| error_message "Error when getting list of Yaml files from directory (${input})." 42

		debug_message "| Start while loop to manage all Yaml files."
		while IFS= read -r w_input_file; do
			## Input filename without extension (remove .yml|.yaml extension)
			w_input_file_basename="$(basename "${w_input_file}" | sed 's/.yml\|.yaml//')"
			## Generate output_file_name according to input informations (eg. defaults/main.yml will become defaults_main.md)
			w_output_file_name="$(basename ${input})_${w_input_file_basename}.md"
			w_output_file_path="${dest_dir}/${w_output_file_name}"

			## Build new Markdown file
			manage_markdown_content "${w_input_file}" "${w_output_file_path}" \
				|| error_message "Can't manage Markdown content from input file (${w_input_file}) to a new file (${w_output_file_path}). See error code : ${?}" "${?}"

			### Ensure to unset loop's vars
			unset w_input_file_basename
			unset w_output_file_name
			unset w_output_file_path

		done < "${yaml_file_list}"

		debug_message "-- manage ${input} directory content END"

		## Exit the script with success
		debug_message "--- MAIN script finish with success"
		exit 0
	fi
	## }}}

	## If ignore_empty mode is set {{{
	## && Print debug message
	## && Exit with success
	[ "${ignore_empty_dir}" -eq "0" ] \
		&& debug_message "--- MAIN ignore_empty mode enable, exit with success." \
		&& exit 0
	## }}}

}
# }}}

# Manage arguments                                                # {{{
# This code can't be in a function due to argument management

if [ ! "${NBARGS}" -eq "0" ]; then

	manage_arg="0"

	## If the first argument is not an option
	if ! printf -- '%s' "${1}" | grep -q -E -- "^-+";
	then
		## Print help message and exit
		printf '%b\n' "${RED}Invalid option: ${1}${RESET}"
		printf '%b\n' "---"
		usage

		exit 1
	fi

	# Parse all options (start with a "-") one by one
	while printf -- '%s' "${1}" | grep -q -E -- "^-+"; do

	case "${1}" in
		-d|--dest|--destination )             ## Define dest_dir_arg with argument
			## Move to the next argument
			shift
			## Define var
			readonly dest_dir_arg="${1}"
			;;
		--debug )                             ## debug
			DEBUG=0
			debug_message "--- Manage argument BEGIN"
			;;
		-h|--help )                           ## help
			usage
			## Exit after help informations
			exit 0
			;;
		--ignore-empty-directory )            ## Set ignore_empty_dir mode
			ignore_empty_dir=0
			;;
		-i|--input|--input-dir )              ## Define input_arg with argument
			## Move to the next argument
			shift
			## Define var
			readonly input_arg="${1}"
			;;
		--grep-exclude-regexp )               ## Define grep_exclude_regexp with argument
			## Move to the next argument
			shift
			## Define var
			readonly grep_exclude_regexp="${1}"
			;;
		* )                                   ## unknow option
			printf '%b\n' "${RED}Invalid option: ${1}${RESET}"
			printf '%b\n' "---"
			usage
			exit 1
			;;
	esac

	debug_message "| ${RED}${1}${COLOR_DEBUG} option managed."

	## Move to the next argument
	shift
	manage_arg=$((manage_arg+1))

	done

	debug_message "| ${RED}${manage_arg}${COLOR_DEBUG} argument(s) successfully managed."
else
	debug_message "| No arguments/options to manage."
fi

	debug_message "--- Manage argument END"
# }}}

main

# This code should not be reached
exit 255
