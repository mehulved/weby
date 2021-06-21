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

# Create database
echo "Creating database..."
bundle exec rake db:create
echo "Database created."

# Load Schema
echo "Loading database schema..."
bundle exec rake db:schema:load RAILS_ENV=$RAILS_ENV DISABLE_DATABASE_ENVIRONMENT_CHECK=1
echo "Schema loaded."

# Run migrations
echo "Running migrations..."
bin/rails db:migrate RAILS_ENV=$RAILS_ENV
echo "Migrations completed."

# Add seed data
echo "Seeding database..."
bundle exec bin/rails db:seed RAILS_ENV=$RAILS_ENV
echo "Database seeded."


rails s -b 0.0.0.0 -p 3000
