JOB_URL=http://admin:a007078b3f1b67785b8c1f07f1b56af4@localhost:8080/job/Dummy
JOB_STATUS_URL=${JOB_URL}/lastBuild/api/json

echo "JOB URL IS :" $JOB_URL

GREP_RETURN_CODE=0

# Start the build
#curl $JOB_URL/build?delay=0sec

# Poll every thirty seconds until the build is finished
while [ $GREP_RETURN_CODE -eq 0 ]
do
    sleep 5
    # Grep will return 0 while the build is running:
    curl --silent $JOB_STATUS_URL | grep result\":null > /dev/null
    GREP_RETURN_CODE=$?
done

echo Build finished
