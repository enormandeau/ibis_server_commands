# Katak and Manitou utilitiy functions
# Source at the bottom of your bashrc file (~/.bashrc)

# Get server name to get maximum CPU and RAM ressources
SERVER=$(hostname)
GROUP=$(groups | cut -d " " -f 1)
if [[ "$SERVER" == "katak" ]]
then
    MAX_CPU=60
    MAX_RAM=1000
fi

if [[ "$SERVER" == "manitou" ]]
then
    MAX_CPU=128
    MAX_RAM=1900
fi

if [[ "$SERVER" == "thoth" ]]
then
    MAX_CPU=280
    MAX_RAM=4300
fi

# Help on these useful commands
function useful_ibis_commands {
    echo
    echo "Useful commands available on $SERVER"
    echo "----------------------------------------------------------"
    echo "h, shelp, useful_ibis_commands:   This help"
    echo "githelp, useful_git_commands:     Useful git commands help"
    echo "----------------------------------------------------------"
    echo

    echo "srun:             Submit job interactively (add '&' to get prompt)"
    echo "srunlive          Start an interactive bash job for 1 hour"
    echo "sbatch:           Submit job from a script"
    echo "scancel:          Cancel a job"
    echo "scancellist <keyword>     List all jobs with keyword"
    echo "scancelall <keyword>      Cancel all jobs with keyword (use scancellist first)"
    echo

    echo "s:                Display job queue, user jobs, ressource usage for group"
    echo "sdep:             Same as 's' but also lists user jobs with dependencies"
    echo "sq:               Display only job queue"
    echo "sqm, sm:          Same as 'sq' but only display your jobs"
    echo "sprio:            Display priority of jobs waiting to be launched"
    echo "partitions:       List available partitions on the current server"
    echo "slurm_header      Create example SLURM batch file (you can pass a file name)"
    echo "srun_examples     Display example srun commands"
    echo "ressourcesUsed    Display ressources used by a job (needs a job number)"
    echo "dfh:              Display disk space for group"
    echo

    echo "report            Display server usage during past week (20 users)"
    echo "report_full       Display server usage during past week (all users)"
    echo "report_month      Display server usage during past month (20 users)"
    echo "report_year       Display server usage during past year (20 users)"
    echo
}

#echo "Type 'h' or 'shelp' for list of useful SLURM related commands"
alias shelp='useful_ibis_commands'
alias h='useful_ibis_commands'

# Functions to report CPU, memory and GPU usage
# CPU
function cpu_sum {
    echo $(sq | grep -vP '_\[|jupyter' | awk '$6 == "R" {print $4}')
}

function cpu_report {
    echo -e "CPU:" $(echo $(cpu_sum) | perl -pe 's/\s/\n/g' | awk '{s+=$1}END{print s}') / "$MAX_CPU" "CPUs"
}

## Memory
function mem_sum {
    echo $(sq | awk '$6 == "R" {print $11}' | perl -pe 's/\.\d+//; s/G/000/; s/M//' | awk '{s+=$1}END{print s}') / 1000 |
        bc |
        cut -c -7
}

function mem_report {
    echo "RAM:" $(echo $(mem_sum) | cut -d "." -f 1) / "$MAX_RAM" Go
}

## GPU
function gpu_usage {
result=$(squeue -o "%b %A %u   %t     %P" | grep gpu)
if [[ -z "${result}" ]]
	then
	printf "\nList of jobs using or waiting for GPU usage\n"
#	date '+%Y-%m-%d %H:%M:%S'
	printf "No GPU usage at this time\n\n"
else
#	date '+%Y-%m-%d %H:%M:%S'
	printf "\nList of jobs using or waiting for GPU usage\n"
	printf "\nGPU:# JobID    User   Status  Partition\n"
	squeue -o "%b %A %u %t       %P" | grep gpu
	#printf "\nFor each job, # in the first column is for number of GPU running (R) or pending (PD)\n"
	#nbrun=$(squeue -o "%b %A %t" | grep gpu | grep R | cut -d':' -f2 | cut -d' ' -f1 | paste -sd+ | bc)
	#nbpdi=$(squeue -o "%b %A %t" | grep gpu | grep PD | cut -d':' -f2 | cut -d' ' -f1 | paste -sd+ | bc)

	#if [[ -z "${nbpdi}" ]]
	#	then nbpdi="0"
	#fi
	#printf "\nTotal number of GPU running: ${nbrun}"
	#printf "\nTotal number of GPU waiting: ${nbpdi}\n\n"
fi
}

## List and cancel all jobs with name beginning with a certain string
function scancellist { sq | grep $1; }
function scancelall { sq | grep $1 | awk '{print $1}' | parallel scancel; }

# Usefull functions
## Nicer df -h output
function dfh {
    df -h 2>/dev/null | grep -E --color=never 'Filesystem|'$GROUP
}

## Nicer squeue output format
function sq {
    squeue -o "%.10i %.9P %.12j %.3C %.8u %.2t %.11M %.11l %.3D %.19R %.7m" |
    grep -E "^|$USER"
}

function sqm {
    sq | grep -E "$USER|JOBID"
}

alias sm='sqm'

function s {
    echo "### Overview"
    sq | grep -v Dependency | grep -v AccountNotA | grep -E "^|.*$USER.*"
    echo
    #echo "### My jobs"
    #sacct --format="CPUTime,MaxRSS,AveRSS,JobName,State,Timelimit,Start,Elapsed" | head -2
    #sacct --format="CPUTime,MaxRSS,AveRSS,JobName,State,Timelimit,Start,Elapsed" |
    #    grep -vE "RUNNING|Elapsed|-----|CANCELLED" | tail -n -10
    #sacct --format="CPUTime,MaxRSS,AveRSS,JobName,State,Timelimit,Start,Elapsed" | grep RUNNING
    #echo
    mem_report
    cpu_report
    gpu_usage
    echo
    dfh
    echo
}

## Partitions available and limits per user
function partitions {
    sinfo
    echo
    sacctmgr list qos format="Name,MaxWall,MaxTRESPerUser%20,GrpTRES" | column -t
    echo
    echo "Max ressources per user"
    echo "-----------------------"
    echo "Server     CPU   Memory"
    echo "Katak       20     300G"
    echo "Manitou     40    1000G"
}

function dep {
    sq | grep -E "JOBID|$USER" | grep -E "JOBID|Dependency" | sort -n
}

function sdep {
    s
    echo
    echo "### Dependencies"
    dep | grep -E "^|.*$USER.*"
}

function ressourcesUsed {
    sacct -j $1 -o MaxRSS,Elapsed,AllocCPUS,JobID,AveCPU,ReqMem,User
}

## Run quick interactive job for 1 hour --pty bash
function srunlive {
    echo
    echo ">> Launching interactive bash shell for one hour"
    echo ">> Do not forget to 'exit' when finished"
    echo

    srun -c 1 --mem 10G --time 1:00:00 --pty bash
}

## Create basic SLURM header script
function slurm_header {
    output_file="$1"

    ## Test if input filename was given
    if [[ -z "$output_file" ]]
    then
        output_file="job_example.sh"
    fi

    ## Test if file already exists to avoid over-writing
    if [[ -e "$output_file" ]]
    then
        echo "WARNING! File already exists, chose another name."
    else
        cat /prg/bashrc/SLURM_example.sh > "$output_file"
    fi
}

function srun_examples {
    echo "Run job with default ressources (add '&' to get prompt back)"
    echo
    echo "    srun sleep 3"
    echo
    echo "Run job that requires terminal emulation (eg: rsync)"
    echo
    echo "    srun --pty rsync -avhP thisfile /move/it/here/"
    echo
    echo "Run interactive job"
    echo
    echo "    srun --pty bash"
    echo
    echo "Run job with other ressource specifications:"
    echo
    echo "    srun -p medium -c 2 --mem 20G --time 1-24:00:00 -J jobname -o jobname%j.log sleep 3"
    echo
}

## Report server activity over last month
function report_year {
    sreport -t hourper cluster Utilization start=`date -d "last year" +%D` end=`date -d "tomorrow" +%D`| cut -c -86
    sreport user top start=`date -d "last year" +%D` end=`date -d "tomorrow" +%D` TopCount=20 -t hourper --tres=cpu,gpu | grep -E "^|.*$USER.*"
}

function report_month {
    sreport -t hourper cluster Utilization start=`date -d "last month" +%D` end=`date -d "tomorrow" +%D`| cut -c -86
    sreport user top start=`date -d "last month" +%D` end=`date -d "tomorrow" +%D` TopCount=20 -t hourper --tres=cpu,gpu | grep -E "^|.*$USER.*"
}

function report {
    sreport -t hourper cluster Utilization start=`date -d "last week" +%D` end=`date -d "tomorrow" +%D` | cut -c -86
    sreport user top start=`date -d "last week" +%D` end=`date -d "tomorrow" +%D` TopCount=20 -t hourper --tres=cpu,gpu | grep -E "^|.*$USER.*"
}

function report_full {
    sreport -t hourper cluster Utilization start=`date -d "last week" +%D` end=`date -d "tomorrow" +%D` | cut -c -86
    sreport user top start=`date -d "last week" +%D` end=`date -d "tomorrow" +%D` TopCount=100 -t hourper --tres=cpu,gpu | grep -E "^|.*$USER.*"
}

# Git
function useful_git_commands {
    echo
    echo "Aliases to common Git commands"
    echo "------------------------------"
    echo "gs:   git status"
    echo "gd:   git diff --color"
    echo "ga:   git add"
    echo "gii:  git commit -m"
    echo "gp:   git push"
    echo "gpu:  git pull --no-rebase"
    echo "gg:   Display list of commits"
    echo
    echo "Aliases to less common Git commands"
    echo "-----------------------------------"
    echo "gb:   git branch"
    echo "gi:   git commit"
    echo "gc:   git checkout"
    echo
}

alias githelp='useful_git_commands'

## Aliases for common git commands
alias gg='git log --oneline --graph --all --decorate --color'
alias gs='git status'
alias gd='git diff --color'
alias ga='git add'
alias gii='git commit -m'
alias gp='git push'
alias gpu='git push --no-rebase'

## Less common git commands
alias gb='git branch'
alias gi='git commit'
alias gc='git checkout'
