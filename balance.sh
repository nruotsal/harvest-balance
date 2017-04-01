#!/usr/bin/env sh

if [ -z $1 ]; then
    echo "
        Script to get your harvest hour balance
        ---
        Usage: ./balance.sh <account> <usename>
        Example: ./balance.sh example user@example.com
    "
    exit 0
fi

account=$1
user=$2
read -s -p "Enter Password: " password

first_day_of_year=$(date -j +%Y0101)
today=$(date -j +%Y%m%d)
GREEN='\033[0;32m'

get_user_info() {
    token=$(create_token $user $password)

    echo $(curl --silent --request GET \
      --url "https://$account.harvestapp.com/people/$user" \
      --header "accept: application/json" \
      --header "authorization: Basic $token" \
      --header "cache-control: no-cache" \
      --header "content-type: application/json")
}

create_token() {
    printf "$1:$2" | base64
}

get_hour_entries() {
    token=$(create_token $user $password)
    user_id=$(parse_user_id $1)

    echo $(curl --silent --request GET \
      --url "https://$account.harvestapp.com/people/$user_id/entries?from=$first_day_of_year&to=$today" \
      --header "accept: application/json" \
      --header "authorization: Basic $token" \
      --header "cache-control: no-cache" \
      --header "content-type: application/json")
}

parse_user_id() {
    echo $1 | jq '.user.id'
}

calculate_hour_balance() {
    user_capacity=$(parse_user_capacity $1)
    first_entry_date=$(parse_first_entry_date $2)
    weeks_worked=$(calculate_weeks_worked $first_entry_date)
    hours_spent=$(calculate_hours_spent $2)
    total_capacity=$(calculate_total_capacity $weeks_worked $user_capacity)

    echo "$hours_spent - $total_capacity" | bc -l
}

parse_user_capacity() {
    echo $1 | jq '.user.weekly_capacity / 3600'
}

parse_first_entry_date() {
    echo $1 | jq -r '.[0].day_entry.spent_at'
}

calculate_weeks_worked() {
    diff_today=$(date -j -f "%Y%m%d" "$today" "+%s")
    diff_first_entry=$(date -j -f "%Y-%m-%d" "$1" "+%s")
    echo $(ceil $(echo "($diff_today - $diff_first_entry) / (60 * 60 * 24) / 7" | bc -l))
}

ceil() {
    printf "%.0f" "$1"
}

calculate_hours_spent() {
    echo $1 | jq 'map(.day_entry.hours) | add'
}

calculate_total_capacity() {
    echo "$1 * $2" | bc -l
}

user_info=$(get_user_info)
entries=$(get_hour_entries $user_info)
balance=$(calculate_hour_balance $user_info $entries)

echo $GREEN"
Your current balance is $balance hours.
"
