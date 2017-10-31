set +x
set +e

echo "hello Jay and Rishi"

#parameters
#1. Branch Name
#2. Repository Name/Variable
#3. 
#-----------------------------

#Algorithm
#1. Fetch latest branch from GIT - Clone repo, yada yada yada
#2. Enter params as list of jobs
#3. Validate if all names provided by user is present in GIT Repo(compulsory)
#4. Throw error even if a single name doesnt match
#5. Loop throught all the jobs
#6. If job doesnt exist
#	create jenkins job with command 
#		curl -X POST -H "Content-Type:application/xml" -d @config.xml http://$jenkins_admin_username:$jenkins_admin_token@$jenkins_hostname:8080/createItem?name=TestBarometers_job
#7. if job exists do an update to the config.xml
#	  a. get the original config.xml and backit up - restAPI/Command/DateStamp/JOB_NAME/config.xml
#			# Get current config
#				curl -X GET http://$jenkins_admin_username:$jenkins_admin_token@$jenkins_hostname:8080/job/test/config.xml -o mylocalconfig.xml
#	  b. update the config.xml by running this commnad
#	         # Post updated config
#				curl -X POST http://$jenkins_admin_username:$jenkins_admin_token@$jenkins_hostname:8080/job/test/config.xml --data-binary "@mymodifiedlocalconfig.xml"
#8. Say thank you

#------------------------------

#_branchName=$1
source scripts/jobUpdater.properties
_listOfJobsRequested=$1

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

## look no git hub coding here :)
#  validate if the job names exist in the branch
cd jobs

for i in $(echo $_listOfJobsRequested | sed "s/,/ /g")
do
   

    if [ ! -d "$i" ]; then
		echo "folder $i doesnt exist in GIT , Please check again. Now exiting!"
		exit 1
		#exit, dont update anything because this folder requested by the executor doesnt exist in GIT;
    fi

done

#if this reaches this stage that means folder checks are done and good to create or update
touch jobStatsFile.txt
#loop through all the jobs
for i in $(echo $_listOfJobsRequested | sed "s/,/ /g")
do
	
	STATUS="NA"
	COMMENT="NA"
	
    #check if folder exists
    if [  -d "$i" ]; then
        echo "folder $i exists"
        ls -la  $i/config.xml

        #check if job config exists at target
        curl -X GET $jenkins_protocol://$jenkins_admin_username:$jenkins_admin_token@$jenkins_hostname:$jenkins_port/job/$i/config.xml -o mylocalconfig.xml
        #sleep for 3 seconds , so allow the shell to catchup with the file
        sleep 3

        #404 signifies that the config was not present, so will create it
        if grep -q "404" mylocalconfig.xml; then
			 
   			 printf "${GREEN}Jenkins job $i doesnt exist in the destination, CREATE ${NC} \n"
			 STATUS="CREATED"
   			 curl -X POST -H "Content-Type:application/xml" -d @$i/config.xml $jenkins_protocol://$jenkins_admin_username:$jenkins_admin_token@$jenkins_hostname:$jenkins_port/createItem?name=$i
			 
		else
			 #if no 404, then the config is present and job is not running, so go ahead and update it
			 
			 curl $jenkins_protocol://$jenkins_admin_username:$jenkins_admin_token@$jenkins_hostname:$jenkins_port/job/$i/lastBuild/api/json | grep --color result\":null
			
			 if [ $? -eq 0 ]; then
				 printf "${RED}Jenkins job exists with $i name in the destination, but is currently Running, WILL NOT UPDATE${NC}\n"
				 STATUS="NOT UPDATED"
				 COMMENT="Job is still running so will not update."
			 else
	    		 printf "${GREEN}Jenkins job exists with $i name in the destination, UPDATE${NC}\n"
	    		 curl -X POST $jenkins_protocol://$jenkins_admin_username:$jenkins_admin_token@$jenkins_hostname:$jenkins_port/job/$i/config.xml --data-binary "@$i/config.xml"
				 STATUS="UPDATED"
				 
			 fi
			 
    		 
		fi
		#remove the temporary file
		rm -rf mylocalconfig.xml

      
    fi
	
	if [[ $STATUS == "NOT UPDATED" ]]; then
		printf "$i \t ${RED}$STATUS${NC} \t $COMMENT\n" >> jobStatsFile.txt
	else
		printf "$i \t ${GREEN}$STATUS${NC} \t $COMMENT\n" >> jobStatsFile.txt
	fi

done

printf "${BLUE}######################## REPORT START ###############################${NC}\n"
cat jobStatsFile.txt
printf "${BLUE}######################## REPORT END   ###############################${NC}\n"
rm jobStatsFile.txt

#USAGE printf "I ${RED}love${NC} Stack Overflow\n"
#Reference of Colour Codes
#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37






