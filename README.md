Harvest hour balance
---

Simple script to check your hour balance starting from the first entry of the year.

Written for OSX. Is not portable, because `date` is different in OSX than other POSIX environments.

### Prerequisites

This script uses [jq](https://stedolan.github.io/jq/) to parse JSON.
You can install it example with brew `brew install jq`

### Usage
    Usage: ./balance.sh <account> <usename>
    Example: ./balance.sh example user@example.com
