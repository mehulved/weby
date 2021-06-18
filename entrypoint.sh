#!/bin/bash

set -e

# Create database
echo "Creating database..."
bundle exec rake db:create
echo "Database created."

# Load Schema
echo "Loading database schema..."
bundle exec rake db:schema:load
echo "Schema loaded."

# Run migrations
echo "Running migrations..."
bin/rails db:migrate RAILS_ENV=$RAILS_ENV
echo "Migrations completed."

# Add seed data
echo "Seeding database..."
bundle exec bin/rails db:seed RAILS_ENV=$RAILS_ENV
echo "Database seeded."

# Precompile the assets
echo "Pre-compiling Assets"
if [[ "$RAILS_ENV" == "production" ]]
then
    bundle exec rake assets:precompile --trace
fi



rails s -b $WEBY_HOSTNAME -p 3000
