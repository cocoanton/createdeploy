##preface
This script helps you set up a repository to a webserver so you can deploy files with git.
The script is based on the guide on how to do this I found at Digitalocean.com called [How to set up automatic deployment with git](https://www.digitalocean.com/community/tutorials/how-to-set-up-automatic-deployment-with-git-with-a-vps)

This script does a few assumptions
* your system uses sudo and you are doing this as the user you will connect with ssh
* you have git installed on the server
* you and your web server are members of the www-data group

##Setting up the enviorment

###Paths
Out of the box, this script assumes that your webserver root directory is /srv/ and that your websites are in there. This might not work for you, no problem! Just edit the line that starts with wwwroot="/srv/" and make that what ever suits your setup.

The same is to be said about the place for the repositories. I have choose to follow the above guide and have put my gits in /var/repo, if this doesn't work for you, change that. This folder needs to be created and all users who are going to deploy code to the server needs to have reading rights for it. 

###Permissions
Best way is just to make yourself, all other users that should deploy code and the webserver part of the www-data group. If you have another group that works fine, you can change this in the script. 

###Place the script
A good place to put the script is ```/usr/local/bin```, this way it's accessible to the users on the server and a pretty standard place to have stuff that helps you.


##Usage of the script

To create a folder  (or use an exisiting folder, if the folder exists it will just let the folder be) in the wwwroot called foobar.com and a git repository to use as an endpoint run ```createdeploy foobar.com```

This will create an folder(if needed) in the wwwroot, and also the folder ```/var/repo/foobar.com/deploy.git```. Then it creates an empty git repository in that directory with the command ```git init --bare```. After that is done, it creates a hook in the repository called ```/var/repo/foobar.com/deploy.git/hooks/post-recieve```. The hook is a bash script which just check outs the code from the repository to ```/srv/foobar.com```. This hook will be run after each push to the repository. [More about Git hooks here](http://git-scm.com/book/en/Customizing-Git-Git-Hooks)


you can get all the options and usage by using --help as an option
```
createdeploy [--remove] [--help] [--wwwroot=/srv] [--wwwgroup=www-data] [--reponame=deploy] [--reporoot=/var/repo] folder_name 
OPTION		LONG OPTION			  MEANING
-?		    --help				  This information
-R		    --remove			  Remove the folder_name from the wwwroot and reporoot
-V		    --verbose			  Verbose information
-wr=<dir>	--wwwroot=<dir>			Directory for the www files, overrides /srv
-wg=<group>	--wwwgroup=<group>		Group name for the web server, overrides www-data
-rn=<name>	--reponame=<name>		The name of the repository inside the reporoot, overrides deploy
-rr=<dir>	--reporoot=<dir>		Directory for the repo files, overrides /var/repo
```


##Deploy code
Ok, now the server is set up, time to push the code!
If your codebase isn't already managed by git, run ```git init``` to setup git for the folder, then add all the files by ```git add .```. Commit the files ```git commit -m "filling the void"```

Then we need to add the remote repository. this is done by ```git remote add deploy ssh://username@foobar.com/var/repo/foobar.com/deploy.git```
and now you are ready. To push your latest commits to the server just run ```git push deploy master```. 

##Improvements
If you have commands that you want or need to run after pushing your files you can add this to the post-recieve bash script. One way would to create a file in the codebase that the hook always run when the code is pushed