#!/bin/zsh

declare -A commands_table

readonly CONFIG_PATH=$HOME/.config/shelf
readonly SHELF_LIST=$CONFIG_PATH/shelf_list.sh

commands_table[open]="<id> Open a previously added bmark"
commands_table[add]="<id> <file> Add a new bmark with <id> to <file>"   
commands_table[remove]="<id> Remove a previously added bmark"     
commands_table[list]="List all bmarks"

prog_name=$( basename -- $ZSH_ARGZERO)

if [[ -d $CONFIG_PATH ]]; then 
        if [[ -f $SHELF_LIST ]]; then 
                source $SHELF_LIST
        fi
        declare -A shelf_list
else 
        mkdir $CONFIG_PATH
        declare -A shelf_list
fi


function usage {
        echo "usage: $prog_name [command] <?arg(s)>"
        for com msg in "${(@kv)commands_table}"; do
                printf "\t%s \t%s\n" $com $msg
        done
}

function open {

        if [[ $# < 1 ]]; then 
                echo "Missing argument."
                usage 
                exit 1
        fi

        if [[ -z $shelf_list[$1] ]]; then 
                echo "No mark with id '$1'."
                exit 1
        else
                file=${shelf_list[$1]}
                if command -v mimeo &> /dev/null; then 
                        mime_info=`mimeo -c $file 2> /dev/null`
                        program=`echo $mime_info | awk '{print $1}'`
                elif command -v xdg-open &> /dev/null; then
                        program="xdg-open"
                else 
                        echo "No suitable xdg-open compatible mime manager."
                fi

                if [[ -f $file ]]; then 
                        $program $file &!
                else 
                        echo "$file: no such file or directory."
                        exit 1
                fi
        fi
}


function add {

        if [[ $# < 2 ]]; then 
                echo "Missing argument(s)."
                usage 
                exit 1
        fi

        if [[ ! -z $shelf_list[$1] ]]; then 
                echo "$1: already exists in list as ${shelf_list[$1]}."
                exit 1
        else
                if [[ $2 != /* ]]; then 
                        file="$(pwd)/$2"
                else 
                        file=$2
                fi

                shelf_list[$1]="$file"
                typeset -p shelf_list > $SHELF_LIST

        fi
}

function remove {

        if [[ $# < 1 ]]; then 
                echo "Missing argument."
                usage 
                exit 1 
        fi

        if [[ ! -z $shelf_list[$1] ]]; then 

                unset "shelf_list[$1]"
                typeset -p shelf_list > $SHELF_LIST
                source $SHELF_LIST

                if [[ -z $shelf_list[$1] ]]; then 
                        echo "Correctly removed mark with id '$1'."
                else 
                        exit 1
                fi
        else
                echo "id $1 not found."
                exit 1
        fi

}

function list {



        if [[ ${#shelf_list[@]} == 0 ]]; then 
                echo "No ids in mark list."
                return
        fi

        printf "\tID\t\tPATH\n"; 

        for name in "${(@k)shelf_list}"; do
                printf "\t%s\t\t%s\n" "$name" "${shelf_list[$name]}"
        done

}


if [[ $# == 0 ]]; then 

        echo "No arguments supplied."
        usage
        exit 1

else 
        for com in "${(@k)commands_table[@]}"; do 
                if [[ $1 == $com ]]; then 
                        $com $2 $3
                        exit 0
                fi
        done

        echo "Command not found."
        usage
        exit 1
fi