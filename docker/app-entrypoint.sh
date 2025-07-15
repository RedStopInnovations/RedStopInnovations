#!/bin/sh

set -e

echo "Environment: $RAILS_ENV"

# install missing gems
bundle check || bundle install --jobs 20 --retry 5

# Remove pre-existing puma/passenger server.pid
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

# run passed commands
bundle exec ${@}