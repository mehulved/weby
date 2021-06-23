#!/bin/bash

set -e

# Delete old PID if it exists
if [ -f "tmp/pids/server.pid" ]
then
    rm -f tmp/pids/server.pid
fi

# Create logs directory if it doesn't exist
if [ ! -d "/weby/log" ]
then
    mkdir /weby/log/
fi

if bundle exec rake db:exists; then
  # Run migrations
  echo "Running migrations..."
  bundle exec rake db:migrate
  echo "Migrations completed."
else
  # Create database
  echo "Creating database..."
  bundle exec rake db:create
  echo "Database created."

  # Run migrations
  echo "Running migrations..."
  bundle exec rails db:migrate
  echo "Migrations completed."

  # Add seed data
  echo "Seeding database..."
  bundle exec bin/rails db:seed RAILS_ENV=$RAILS_ENV
  echo "Database seeded."
fi


rails s -b 0.0.0.0 -p 3000
