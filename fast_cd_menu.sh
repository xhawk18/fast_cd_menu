

function c() {
local _cd_on_left=1

function _cd_get_cur_pos() {
    echo -ne "\033[6n" > /dev/tty
    local SAVE_IFS="$IFS"
    local pos
    IFS= read -sdR pos
    IFS="$SAVE_IFS"
    echo -ne "\033[0m"
    row="${pos%%;*}"
    row="${row##*[}"
    col="${pos##*;}"
    echo "$col $row"
}

if type readarray >/dev/null 2>&1; then
function _cd_get_lines() {
    local lines=()
    echo "$*" | {
        readarray -t lines
        echo "${#lines[@]}"
    }
}
else
function _cd_get_lines() {
    echo "$*" | { 
        local line
        local num=0
        while read line; do
            ((num++))
        done
        echo "$num"
    }
}
fi

if type readarray >/dev/null 2>&1; then
function _cd_get_one_line() {
    local i="$1"
    local list="$2"
    local lines=()
    echo "$list" | {
        readarray -t lines
        if ((i < ${#lines[@]})); then
            echo "${lines[$i]}"
        fi
    }
}
else
function _cd_get_one_line() {
    local i="$1"
    local list="$2"
    echo "$list" | {
        local line
        local num
        while read line; do
            if ((num == i)); then
                echo "$line"
                break
            fi
            ((num++))
        done
    }
}
fi

function _cd_show_colored_line() {
    local highlight="$1"
    local dir="$2"
    local file="$3"
    local hl_pos="$4"
    local hl_len="$5"
    if [[ "$highlight" == "Y" ]]; then
        if ((_cd_on_left && ${#@} >= 6)); then
            local num="$6"
            echo -ne "\033[7m\033[32m$num\033[0m\033[7m:"
        fi
        echo -ne "\033[7m"
        echo -n "${dir}"
        echo -ne "\033[33m"
        if ((hl_pos >= 0)); then
            echo -n "${file:0:$hl_pos}"
            echo -ne "\033[31m"
            echo -n "${file:$hl_pos:$hl_len}"
            echo -ne "\033[33m"
            echo -n "${file:$hl_pos+$hl_len}"
        else
            echo -n "${file}"
        fi
        if ((!_cd_on_left && ${#@} >= 6)); then
            local num="$6"
            echo -ne "\033[0m\033[7m:\033[32m$num"
        fi
        echo -ne "\033[0m"
    else
        if ((_cd_on_left && ${#@} >= 6)); then
            local num="$6"
            echo -ne "\033[1m\033[32m$num\033[0m:"
        fi
        echo -n "${dir}"
        echo -ne "\033[1m\033[33m"
        if ((hl_pos >= 0)); then
            echo -n "${file:0:$hl_pos}"
            echo -ne "\033[0m\033[7m\033[31m"
            echo -n "${file:$hl_pos:$hl_len}"
            echo -ne "\033[0m\033[1m\033[33m"
            echo -n "${file:$hl_pos+$hl_len}"
        else
            echo -n "${file}"
        fi
        if ((!_cd_on_left && ${#@} >= 6)); then
            local num="$6"
            echo -ne "\033[0m:\033[1m\033[32m$num"
        fi
        echo -ne "\033[0m"
    fi
}

function _cd_console_length() {
    local s="$1"
    #echo -n "$s" | wc -c
    #echo -n "${#s}"
    local non_asc="${s//[[:ascii:]]/}"
    echo -n "$(( ${#s} + ${#non_asc} ))"
}

function _cd_shorten_line_ex() {
    local s="$1"
    local len="$2"
    local slen="$(_cd_console_length "$s")"

    if (($len <= 0)); then
        echo "0,0:$s"
    elif (($slen >= $len + 23)); then
        echo "10,$(($slen-$len-13)):${s:0:10}...${s:$len+13}"
    elif (($slen >= $len + 15)); then
        local pos="$(( $slen-$len-13 ))"
        echo "$pos,10:${s:0:$pos}...${s:$slen-10}"
    elif (($slen >= $len + 7)); then
        echo "2,$(($slen-$len-5)):${s:0:2}...${s:$len+5}"
    elif (($slen <= 5)); then
        echo "0,0:$s"
    else
        echo "2,2:${s:0:2}...${s:$slen-2}"
    fi
}

function _cd_shorten_line() {
    local s="$1"
    local len="$2"
    local slen="$(_cd_console_length "$s")"

    if (($len <= 0)); then
        echo "$s"
    elif (($slen >= $len + 23)); then
        echo "${s:0:10}...${s:$len+13}" 
    elif (($slen >= $len + 15)); then
        echo "${s:0:$slen-$len-13}...${s:$slen-10}"
    elif (($slen >= $len + 7)); then
        echo "${s:0:2}...${s:$len+5}"
    elif (($slen <= 5)); then
        echo "$s"
    else
        echo "${s:0:2}...${s:$slen-2}"
    fi
}

function _cd_show_padding() {
    local highlight="$1"
    local len="$2"
    local i
    if [[ "$highlight" == "Y" ]]; then
        echo -ne "\033[7m"
        echo -n "${LONG_BK_LINE:0:$len}"
        echo -ne "\033[0m"
    else
        echo -n "${LONG_BK_LINE:0:$len}"
    fi
}

if (( ${BASH_VERSION%%.*} >= 4 )); then
function _cd_to_upper_case() {
    echo "${@^^}"
}
elif type tr >/dev/null 2>&1; then
function _cd_to_upper_case() {
    echo "$@" | tr "a-z" "A-Z"
}
elif type sed >/dev/null 2>&1; then
function _cd_to_upper_case() {
    echo "$@" | sed -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/'
}
elif type awk >/dev/null 2>&1; then
function _cd_to_upper_case() {
    echo "$@" | awk '{print toupper($0)}'
}
else
function _cd_to_upper_case() {
    echo "$@"
}
fi

function _cd_index_of() {
    local word="$1"
    local search="$2"
    word="$(_cd_to_upper_case "$word")"
    search="$(_cd_to_upper_case "$search")"
    search="${search//\*/\*}"
    search="${search//%/\%}"
    local prev="${word%%${search}*}"
    if [[ "$prev" == "$word" ]]; then
        echo -1
    else
        echo "${#prev}"
    fi
}

function _cd_show_dir_line() {
    local highlight="$1"
    local width="$2"
    local s="$3"
    local search="$4"
    local i
    local file
    local dir
    local num
    if [[ "${s%:}" != "$s" ]]; then
        file="${s%:}"
        file="${file##*/}"
        dir="${s:0:${#s}-${#file}-1}"
        #local len="$(( ${#dir}+${#file} ))"
        local len="$(( $(_cd_console_length "$dir") + $(_cd_console_length "$file") ))"
        if (( $len > $width )); then dir="$(_cd_shorten_line "$dir" "$(($len-$width))" )"; fi
        #len="$(( ${#dir}+${#file} ))"
        len="$(( $(_cd_console_length "$dir") + $(_cd_console_length "$file") ))"
        local hl_pos="$(_cd_index_of "$file" "$search")"
        local hl_len="${#search}"
        if (( $len > $width )); then
            local hl_end="$(( $hl_pos + $hl_len ))"
            local file_ex="$(_cd_shorten_line_ex "$file" "$(($len-$width))" )"
            local pos="${file_ex%%:*}"
            local end="${pos#*,}"
            pos="${pos%,*}"
            local o_end="$((${#file} - $end))"
            local short_file="${file_ex#*:}"
            if ((pos != 0)); then
                if ((o_end <= hl_pos)); then hl_pos="$((hl_pos + ${#short_file} - ${#file} ))"
                elif ((pos <= hl_pos)); then hl_pos="$pos"; fi
            fi
            if ((pos != 0)); then
                if ((o_end <= hl_end)); then hl_end="$((hl_end + ${#short_file} - ${#file} ))"
                elif ((pos <= hl_end)); then hl_end="$((${#short_file}-$end))"; fi
            fi
            hl_len="$(($hl_end - $hl_pos))"
            _cd_show_colored_line "$highlight" "$dir" "$short_file" "$hl_pos" "$hl_len"
        else
            if ((!_cd_on_left)); then
                _cd_show_padding "$highlight" "$(($width-$len))"
            fi
            _cd_show_colored_line "$highlight" "$dir" "$file" "$hl_pos" "$hl_len"
        fi
    else
        num="${s##*:}"
        file="${s%:*}"
        file="${file##*/}"

        dir="${s:0:${#s}-${#file}-1-${#num}}"
        #local len="${#s}"
        local len="$(_cd_console_length "$s")"
        if (( $len > $width )); then dir="$(_cd_shorten_line "$dir" "$(($len-$width))" )"; fi
        #len="$(( ${#dir}+${#file}+1+${#num} ))"
        len="$(( $(_cd_console_length "$dir") + $(_cd_console_length "$file") + 1 + ${#num} ))"
        local hl_pos="$(_cd_index_of "$file" "$search")"
        local hl_len="${#search}"
        if (( $len > $width )); then
            local hl_end="$(( $hl_pos + $hl_len ))"
            local file_ex="$(_cd_shorten_line_ex "$file" "$(($len-$width))" )"
            local pos="${file_ex%%:*}"
            local end="${pos#*,}"
            pos="${pos%,*}"
            local o_end="$((${#file} - $end))"
            local short_file="${file_ex#*:}"
            if ((pos != 0)); then
                if ((o_end <= hl_pos)); then hl_pos="$((hl_pos + ${#short_file} - ${#file} ))"
                elif ((pos <= hl_pos)); then hl_pos="$pos"; fi
            fi
            if ((pos != 0)); then
                if ((o_end <= hl_end)); then hl_end="$((hl_end + ${#short_file} - ${#file} ))"
                elif ((pos <= hl_end)); then hl_end="$((${#short_file}-$end))"; fi
            fi
            hl_len="$(($hl_end - $hl_pos))"
            _cd_show_colored_line "$highlight" "$dir" "$short_file" "$hl_pos" "$hl_len" "$num"
        else
            if ((!_cd_on_left)); then
                _cd_show_padding "$highlight" "$(($width-$len))"
            fi
            _cd_show_colored_line "$highlight" "$dir" "$file" "$hl_pos" "$hl_len" "$num"
        fi
    fi
}


function _cd_show_pwd() {
    local file="${PWD##*/}"
    local dir="${PWD:0:${#PWD}-${#file}}"
    echo -en "\r=>"
    _cd_show_colored_line Y "$dir" "$file" -1
    echo ""
}


function _cd_show_list_all() {
    local list="$1"
    if (( ${#list} == 0 )); then return; fi
    echo "$list" | {
        local num=-1
        while read -s dir; do
            (( num++ ))
            echo "$dir:$num"
        done
    }
}

function _cd_show_list() {
    local list="$1"
    local search="$2"
    #if (( ${#list} == 0 )); then return; fi
    echo "$list" | {
        local lines=()
        if type readarray >/dev/null 2>&1; then
            readarray -t lines
        else
            local line
            while read line; do
                lines+=("$line")
            done
        fi
        local num=-1
        if [[ "${search//[0-9]/}" == "" ]]; then
            if ((search < ${#lines[@]})); then
                num="$search"
                echo "${lines[$num]}:$num"
            fi
        fi
        if [[ "$num" != "$search" ]]; then
            local num
            local count=0
            if false; then
                for ((num = 0; num < ${#lines[@]}; ++num)); do
                    local dir="${lines[$num]}"
                    local name="${dir##*/}"
                    if [[ "$(_cd_index_of "$name" "$search")" == "0" ]]; then
                        (( count++ ))
                        echo "$dir:$num"
                    fi
                done
            fi

            if (( $count != 1 )); then
                for ((num = 0; num < ${#lines[@]}; ++num)); do
                    local dir="${lines[$num]}"
                    local name="${dir##*/}"
                    if (( $(_cd_index_of "$name" "$search") >= 0 )); then
                        echo "$dir:$num"
                        (( count++ ))
                    fi
                done
            fi
            
            if [[ -d "$search" ]]; then
                echo "$search:"
                (( count++ ))
            elif [[ -f "$search" ]]; then
                echo "${search%/*}:"
                (( count++ ))
            fi

            if (( $count == 0 )); then
                _cd_show_list_all "$list"
            fi
        fi
    } 
}

function _cd_list() {
    local list="$1"
    local show_all="$2"
    local lines="$(_cd_get_lines "$list")"

    if (( ${#list} == 0 )); then
        echo "< history directories not found! >"
    elif (( $lines == 1 )) && [[ "$show_all" != "show_all" ]]; then
        _cd_save "${list%:*}"
        _cd_show_pwd
    else
        local oldstty="$(stty -g)"
        local oldtrap0="$(trap -p SIGINT)"
        local oldtrap1="$(trap -p SIGALRM)"

        function _cd_menu() {
            trap "return" SIGINT
            trap "" SIGALRM

            # show menu
            echo -ne "\xe\xf"
            echo -ne "\033[?25l"
            stty raw -echo min 0
            local changed=0
            local pos="$(_cd_get_cur_pos)"
            local width="$COLUMNS"  
            local height="$LINES"
            local x="${pos% *}"
            local y="${pos#* }"
            local old_menu_off=0
            local menu_off=0
            local menu_h=$((height<lines?height:lines))
            local i
            for ((i = 1; i < menu_h; ++i)); do echo ; done
            y=$((y+menu_h>height?height-menu_h+1:y))
            local LONG_BK_LINE="$(echo {0..256})"
            LONG_BK_LINE="${LONG_BK_LINE//[0-9]/ }"
            while ((${#LONG_BK_LINE} < 256)); do LONG_BK_LINE="$LONG_BK_LINE$LONG_BK_LINE"; done
            function get_match_index()
            {
                local list="$1"
                local search="$2"
                if [[ "$search" == "" ]]; then return; fi
                echo "$list" | {
                    local lines
                    if type readarray >/dev/null 2>&1; then
                        readarray -t lines
                    else
                        local line
                        while read line; do
                            lines+=("$line")
                        done
                    fi
                    local num
                    for ((num = 0; num < ${#lines[@]}; ++num)); do
                        local line="${lines[$num]}"
                        local file="${line%:*}"
                        file="${file##*/}"
                        if [[ "$(_cd_index_of "$file" "$search")" != "-1" ]]; then
                            echo -n "$num "
                        fi
                    done
                }
            }
            local old_highlight="-1"
            local highlight=0
            local cd_entry="-1"
            local old_search=""
            local search=""
            local akey=(0 0 0)
            while :; do
                local width="$COLUMNS"
                local SAVE_IFS="$IFS"
                IFS=" "
                local nums=( $(get_match_index "$list" "$search") )
                IFS="$SAVE_IFS"
                if ((${#nums[@]} == 1)); then
                    local dir="$(_cd_get_one_line ${nums[0]} "$list")"
                    dir="${dir%:*}"
                    _cd_save "$dir"
                    changed=1
                    break
                fi
                local num=""
                if ((${#nums[@]} > 0)); then num="${nums[0]}"
                elif ((${#nums[@]} == 0)) && [[ "$search" != "" ]]; then
                    if ((${#search} > 1)); then search="${search:${#search}-1}"
                    elif [[ "${#search}" == "1" && "${search//[0-9]}" == "" ]]; then
                        local dir="$(_cd_get_one_line "$search" "$list")"
                        dir="${dir%:*}"
                        _cd_save "$dir"
                        changed=1
                        break
                    else
                        old_search="$search"
                        search=""
                    fi
                    continue
                fi
                if [[ "$num" != "" ]]; then
                    if ((highlight < $num)); then
                        old_highlight=$highlight
                        highlight="$num"
                        if (( menu_off + menu_h <= highlight )); then
                            old_menu_off=$menu_off
                            menu_off=$((highlight - menu_h + 1))
                        fi
                    elif ((highlight > $num)); then
                        old_highlight=$highlight
                        highlight="$num"
                        if (( menu_off > highlight )); then
                            old_menu_off=$menu_off
                            menu_off=$highlight
                        fi
                    fi
                fi
                echo "$list" | {
                    local lines
                    if type readarray >/dev/null 2>&1; then
                        readarray -t lines
                    else
                        local line
                        while read line; do
                            lines+=("$line")
                        done
                    fi
                    local num
                    local numstr
                    local SAVE_IFS="$IFS"
                    IFS=","
                    numstr="${nums[*]}"
                    IFS="$SAVE_IFS"
                    echo -ne "\033[$y;1H"
                    for ((num = 0; num < menu_h; ++num)); do
                        local line="${lines[$((num+menu_off))]}"
                        if (( num != 0 )); then echo; fi
                        if ((num+menu_off == highlight)); then
                            echo -ne "\033[$((y+num));1H"
                            _cd_show_dir_line Y "$width" "$line" "$search"
                        elif ((num+menu_off == old_highlight)); then
                            echo -ne "\033[$((y+num));1H"
                            _cd_show_dir_line N "$width" "$line" "$search"
                        elif ((old_highlight == -1 || menu_off != old_menu_off)) || [[ "$search" != "$old_search" ]]; then
                            echo -ne "\033[$((y+num));1H"
                            _cd_show_dir_line N "$width" "$line" "$search"
                        fi
                    done
                }
                local ESC="$(echo -ne "\033")"
                local LF="$(echo -ne "\n")"       
                local BS="$(echo -ne "\x7F")"
                local WAIT_TIMEOUT="$( if (( ${BASH_VERSION%%.*} >= 4 )); then echo 0.03; else echo 1; fi; )"
                while :; do
                    local key
                    local SAVE_IFS="$IFS"
                    IFS= read -s -n1 key
                    akey[0]="$key"
                    akey[1]=""
                    akey[2]=""
                    if [[ "$key" == "$ESC" ]]; then
                        local i

                        if (( ${BASH_VERSION%%.*} < 4 )); then
                            ( { sleep 0.05; kill -s ALRM $$; } & )
                        fi

                        for ((i = 1; i <= 2; ++i)); do
                            if IFS= read -s -n1 "-t$WAIT_TIMEOUT" key; then
                                akey[$i]="$key"
                            else
                                break
                            fi
                        done
                    fi
                    IFS="$SAVE_IFS"
                    if [[ "${akey[0]}" == "$ESC" && "${akey[1]}" == "[" ]]; then
                        if [[ "${akey[2]}" == "B" ]]; then
                            old_search="$search"
                            search=""
                            if (( highlight + 1 < lines )); then
                                old_highlight=$highlight
                                (( ++highlight ))
                                if (( menu_off + menu_h <= highlight )); then
                                    old_menu_off=$menu_off
                                    menu_off=$((highlight - menu_h + 1))
                                fi
                                break
                            fi
                        elif [[ "${akey[2]}" == "A" ]]; then
                            old_search="$search"
                            search=""
                            if (( highlight > 0 )); then
                                old_highlight=$highlight
                                ((--highlight))
                                if (( menu_off > highlight )); then
                                    old_menu_off=$menu_off
                                    menu_off=$highlight
                                fi
                                break
                            fi
                        elif [[ "${akey[2]}" == "C" ]]; then
                            cd_entry="$highlight"
                            break
                        elif [[ "${akey[2]}" == "D" ]]; then
                            cd_entry="-2"
                            break
                        fi
                    elif [[ "${akey[0]}" == "$ESC" ]]; then
                        if [[ "$search" == "" ]]; then cd_entry="-2"
                        else
                            old_search="$search"
                            search=""
                        fi
                        break
                    elif [[ "${akey[0]}" == "$LF" ]]; then
                        cd_entry="$highlight"
                        break
                    elif [[ "${akey[0]}" == "$BS" ]]; then
                        if ((${#search} > 0)); then
                            old_search="$search"
                            search="${search:0:${#search}-1}"
                            break
                        fi
                    else
                        old_search="$search"
                        search="$search${akey[0]}"
                        break
                    fi
                done
                if (( cd_entry >= 0 )); then
                    local line="$(_cd_get_one_line "$cd_entry" "$list")"
                    line="${line%:*}"
                    _cd_save "$line"
                    changed=1
                    break
                elif (( cd_entry != -1 )); then
                    echo -e '\r';
                    break
                fi
            done

            if [[ "$changed" == "1" ]]; then
                stty "$oldstty"
                echo -e "\033[$((y+menu_h-1));1H"
                _cd_show_pwd
            fi
        }

        _cd_menu
        # Recover tty/sig
        if [[ "$oldtrap1" == "" ]]; then trap SIGALRM
        else eval "$oldtrap1"; fi
        if [[ "$oldtrap0" == "" ]]; then trap SIGINT
        else eval "$oldtrap0"; fi
        echo -ne "\033[?25h"
        stty "$oldstty"
    fi
}

function _cd_get_parent() {
    if [[ "${*//\.}" == "" ]]; then
        local v="$*"
        v=${#v}
        echo $(( v <= 1 ? 0 : (v - 1) ))
    else
        local v="${*#\.\.}"
        if [[ "$v" == "$*" ]]; then echo 0
        elif [[ "${v//[0-9]}" != "" ]]; then echo 0
        else
            echo "$v"
        fi
    fi
}

    local dummy_comment="start of function c() here"

    if [[ "$#" == "1" && "$1" == "--help" ]]; then
        echo "Usage(1): ${FUNCNAME[0]}"
        echo "Usage(2): ${FUNCNAME[0]} [index|sensitive_word|file_path|folder_path]"
        echo "  Super cd command - "
        echo "  change to folder according to history index or file or folder path."
        return
    fi

    if [[ "$*" == "-" ]]; then _cd_save "-"
    elif [[ "$*" == "" ]]; then
        _cd_list "$(_cd_show_list_all "$(if [[ -f "$HOME/.fast_cd/cd_save" ]]; then cat "$HOME/.fast_cd/cd_save"; fi)" )" "show_all"
    elif (( "$(_cd_get_parent "$*")" > 0 )); then
        local v="$(_cd_get_parent "$*")"
        local pwd="${PWD//\/}"
        local max=$((${#PWD} - ${#pwd}))
        _cd_save "$(
            local i
            for ((i = 0; i < v && i < max; ++i)); do
                echo -n "../"
            done; )"
        _cd_show_pwd
    else
        _cd_list "$(_cd_show_list "$(if [[ -f "$HOME/.fast_cd/cd_save" ]]; then cat "$HOME/.fast_cd/cd_save"; fi)" "$*" )" "not_show_all" "$*"
    fi


    unset -f _cd_get_cur_pos
    unset -f _cd_get_lines
    unset -f _cd_get_one_line
    unset -f _cd_show_colored_line
    unset -f _cd_shorten_line_ex
    unset -f _cd_shorten_line
    unset -f _cd_show_padding
    unset -f _cd_to_upper_case
    unset -f _cd_index_of
    unset -f _cd_show_dir_line
    unset -f _cd_show_pwd
    unset -f _cd_show_list_all
    unset -f _cd_show_list
    unset -f _cd_list
    unset -f _cd_get_parent
    unset -f _cd_menu
    unset -f _cd_console_length
}

unalias cd > /dev/null 2>&1 
function _cd_save() {
    cd "$@"
    local pwd="${PWD}"
    local dirs="$(if [[ -f "$HOME/.fast_cd/cd_save" ]]; then cat "$HOME/.fast_cd/cd_save"; fi)"
    local str="$( {
        echo "$dirs" | { 
            local dirs=()
            local dir=""
            if type readarray >/dev/null 2>&1; then
                readarray -t dirs
            else
                local line
                while read line; do
                    dirs+=("$line")
                done
            fi
            for dir in "${dirs[@]}"; do 
                if [[ "$dir" == "$pwd" ]]; then
                    local i
                    for i in "${dirs[@]}"; do echo "$i"; done
                    break
                fi
            done
            if [[ "$dir" != "$pwd" ]]; then
                echo "$pwd"
                local num=0
                for dir in "${dirs[@]}"; do
                    if [[ "$dir" != "$pwd" ]]; then
                        echo "$dir"
                        if (( ++num >= 9 )); then break; fi
                    fi
                done
            fi
        }
    } )"
    mkdir -p "$HOME/.fast_cd"
    echo "$pwd" > "$HOME/.fast_cd/cd_save_last"
    echo "$str" > "$HOME/.fast_cd/cd_save"
}

if [[ false && -f "$HOME/.fast_cd/cd_save_last" ]]; then
    read < "$HOME/.fast_cd/cd_save_last"
    if [[ -d "$REPLY" ]]; then
        cd "$REPLY"
    fi
fi

alias cd=_cd_save
