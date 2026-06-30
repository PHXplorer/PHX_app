echo "Script was launched from: $(pwd)"
echo "Using $DB_DRIVER database"

if [[ ! $(pwd) == */applications/main ]]; then 
  echo "Trying to change working directory to the main application"
  cd ./applications/main
fi

SHINY_START_MESSAGE="Loading required package: shiny"
SHINY_READY_MESSAGE="Listening on"
N_RETRIES=600 # roughly 1 minute

# Remove existing log file & do not report error if file does not exist
rm /tmp/shiny.log 2> /dev/null

echo "Starting shiny app in background mode"
Rscript -e "shiny::runApp(port = 3939L)" 2>&1 | while IFS= read -r line; do printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line"; done > /tmp/shiny.log &

n_attempts=0
while [[ $(grep -ic "$SHINY_READY_MESSAGE" /tmp/shiny.log) -eq 0 ]]; do
  if [[ $(($n_attempts % 10)) -eq 0 ]]; then
    cat /tmp/shiny.log
    # tail -1 /tmp/shiny.log
  fi
  sleep 0.1
  n_attempts=$(($n_attempts+1))

  if [[ $n_attempts -gt $N_RETRIES ]]; then
    echo "Timeout error"
    exit 1;
  fi
done

kill $(lsof -t -i:3939)

if [[ $TEST_LOCATION == "" ]]; then
  location="local"
else
  location=$TEST_LOCATION
fi

echo "Saving benchmark results"
cd ../../

start_time=$(grep "$SHINY_START_MESSAGE" /tmp/shiny.log | sed 's/.*\[\(.*\)\].*/\1/')
ready_time=$(grep "$SHINY_READY_MESSAGE" /tmp/shiny.log | sed 's/.*\[\(.*\)\].*/\1/')

current_branch=$(git rev-parse --abbrev-ref HEAD)
measure_time=$(date '+%Y-%m-%d %H:%M:%S')
echo "$measure_time,$current_branch,$location,$DB_DRIVER,$start_time,$ready_time,no comment" >> ./benchmarks/main-app-startup.csv
