#!/bin/bash
### DEFAULT SETTINGS - CHANGE AS NEEDED ###
wwwgroup="www-data" #this is the group of the webserver
wwwroot="/srv"  #folder of the server
reponame="deploy" #default name of the repository
reporoot="/var/repo" #directory to where you store the repositories
### NO MORE DEFAULT SETTINGS ###

removedirs=NO
verbose=NO
selfname=${0##*/}
usage="\rusage: $selfname [--remove] [--help] [--wwwroot=$wwwroot] [--wwwgroup=$wwwgroup] [--reponame=$reponame] [--reporoot=$reporoot] folder_name \n \rthis will create the folder_name in $wwwroot and a repository in $reporoot"
help="
Git site deploy helper -- created by cocoanton
OPTION\t\tLONG OPTION\t\t\tMEANING
-?\t\t--help\t\t\t\tThis information
-R\t\t--remove\t\t\tRemove the folder_name from the wwwroot and reporoot
-V\t\t--verbose\t\t\tVerbose information
-wr=<dir>\t--wwwroot=<dir>\t\t\tDirectory for the www files, overrides $wwwroot
-wg=<group>\t--wwwgroup=<group>\t\tGroup name for the web server, overrides $wwwgroup
-rn=<name>\t--reponame=<name>\t\tThe name of the repository inside the reporoot, overrides $reponame
-rr=<dir>\t--reporoot=<dir>\t\tDirectory for the repo files, overrides $reporoot
"
##CHECK FOR OVERRIDES OF THE DEFAULT VALUES
for i in "$@"
do
case $i in
    -?|--help)
    echo -e " $usage"
    echo -e " $help"
    exit 1
    shift
    ;;
    -wr=*|--wwwroot=*)
    wwwroot="${i#*=}"
    shift
    ;;
    -wg=*|--wwwgroup=*)
    wwwgroup="${i#*=}"
    shift
    ;;
    -rn=*|--reponame=*)
    reponame="${i#*=}"
    shift
    ;;
    -rr=*|--reporoot=*)
    reporoot="${i#*=}"
    shift
    ;;
    -R|--remove)
    removedirs=YES
    shift
    ;;
    -V|--verbose)
    verbose=YES
    shift
    ;;
    *)
    if [[ ${*} == *\=* || ${*} == -* ]] ; then
    # unknown option
        echo -e "\n$selfname: illegal option ${*}"
        echo -e "$usage"
        exit 1
    fi
    ;;
esac
done

##CHECK IF GIT IS INSTALLED, NO POINT GOING ANY FURTHER IF THERE IS NO GIT
type git >/dev/null 2>&1 || { echo >&2 "This command relies on git and git is not installed.  Aborting."; exit 1; }
##CHECK IF SUDO IS INSTALLED, SINCE WE ARE USING THAT
type sudo >/dev/null 2>&1 || { echo >&2 "This command (stupidly) relies on sudo and sudo is not installed.  Aborting."; exit 1; }


if [ $removedirs = YES ] ; then ##User wants to remove files
    if [ ! -d "$wwwroot/$1" ] ; then ##check that the folder even exists
        echo -e "\nNo folder named $wwwroot/$1"
        exit 1
    fi

    filecount=$(find $wwwroot/$1 -type f | wc -l) ## get a count of the files in the directory
    filecount="${filecount#"${filecount%%[![:space:]]*}"}" ##trim leading spaces

    echo -e "\n$(tput setaf 1)WARNING$(tput sgr0): This will delete $wwwroot/$1 containing $filecount files and also remove the repository $reporoot/$1/$reponame.git is this what you want?"
    read -n3 -p "To continue, type YES: " confirm
    echo -e ""
    if [ $confirm = "YES" ] ; then
        echo -e "deleting files from $wwwroot/$1..."
        sudo rm -rf $wwwroot/$1
        if [ -d "$reporoot/$1/$reponame.git" ] ; then ## check if the repository exists if not, let the user know that
            echo -e "deleting files from $reporoot/$1/$reponame.git..."
        sudo rm -rf $reporoot/$1/$reponame.git
        else
            echo -e "there were no repository at $reporoot/$1/$reponame.git, you might have stray files"
        fi
    else
        echo -e "remove aborted. exiting"
    fi
    exit 1
fi


if [[ $# -eq 0 || $1 == *--* ]] ; then ##check if the user has provided foldername and using the correct usage
    echo -e "\n$usage"
    exit 1
fi
##CHECK IF THE WWWROOT DOES EXIST, WE DO NOT WANT TO CREATE IT IF ISN'T THERE
if [ ! -d "$wwwroot" ]; then
    echo -e "\n$(tput setaf 1)ERROR$(tput sgr0): the web server root does not exist at $wwwroot, provide another directory with --wwwroot=<dir> or create $wwwroot"
    exit 1
fi
##CHECK IF THE REPOROOT DOES EXIST, WE DO NOT WANT TO CREATE IT IF ISN'T THERE
if [ ! -d "$reporoot" ]; then
    echo -e "\n$(tput setaf 1)ERROR$(tput sgr0): the repository root does not exist at $reporoot, provide another directory with --reporoot=<dir> or create $reporoot"
    exit 1
fi

##MAKE RELATIVE URLS FIXED
##store the current directory as reference
old_pwd=$(pwd)
reporoot=$(cd $reporoot; pwd)
wwwroot=$(cd $wwwroot; pwd)
wwwdir="$wwwroot/$1"
repodir="$reporoot/$1/$reponame.git"
##Go back to the folder
cd $old_pwd

##CHECK IF THE WWW-GROUP IS VALID ON THE SYSTEM
checkgroup=$(egrep -i "^$wwwgroup" /etc/group)
if [ ! "$checkgroup" ]; then
    echo -e "\n$(tput setaf 1)ERROR$(tput sgr0): the group $wwwgroup does not exist, provide another groupname with --wwwgroup=<name> or create $wwwgroup"
    exit 1
fi
##JUST GET THE PASSWORD PROMPT for sudo to confirm user
$(sudo -k; sudo -p "Enter password for $USER on %h:" ls > /dev/null)


##check if folder exists, if not, create it
if [ ! -d "$wwwdir" ]; then
    if [ $verbose = YES ] ; then
        echo -e " - making directory '$wwwdir'"
    fi
    sudo mkdir $wwwroot/$1

    if [ $verbose = YES ] ; then
        echo -e " - setting ownership to '$USER:$wwwgroup'"
    fi
    sudo chown $USER:$wwwgroup $wwwroot/$1
else
    if [ $verbose = YES ] ; then
        echo -e " - no need to create '$wwwdir', it exists"
    fi
fi

##check if git repository exists, if not, create it
if [ ! -d "$reporoot/$1" ]; then
    if [ $verbose = YES ] ; then
        echo -e " - creating repository project '$reporoot/$1/'"
    fi
    sudo mkdir $reporoot/$1
fi
##check if git repository exists, if not, create it and init it
if [ ! -d "$repodir" ]; then
    if [ $verbose = YES ] ; then
        echo -e " - creating repository folder '$repodir'"
    fi
    sudo chown $USER:$wwwgroup $reporoot/$1
    mkdir $reporoot/$1/$reponame.git
    if [ $verbose = YES ] ; then
        echo -e " - setting ownership to '$USER:$wwwgroup'"
    fi
    ##init the git repo
    cd $repodir
    if [ $verbose = YES ] ; then
        echo -e " - running git init --bare in '$repodir'"
        git init --bare
        else
        git init --bare >> /dev/null
    fi
    ## navigate back to the folder
    cd $old_pwd
    ## setup the hook
    if [ $verbose = YES ] ; then
        echo -e " - creating the post-recieve hook file in '$repodir/hooks'"
    fi

    echo -e "#!/bin/bash\ngit --work-tree=$wwwdir --git-dir=$repodir checkout -f" >> $repodir/hooks/post-recieve
    chmod +x $repodir/hooks/post-recieve

fi
echo -e "operation done."
echo -e "\r$(tput dim) use '$(tput bold)git remote add $reponame ssh://$USER@$HOSTNAME$repodir$(tput sgr0)' $(tput dim)to add the repository on your machine. \nTo deploy the files from your machine use '$(tput bold)git push $reponame master$(tput sgr0)'"

##Forget the sudo password, just to be careful
sudo -k

exit 0