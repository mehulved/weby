#!/bin/bash

set -e

if [[ -z ${WEBY_HOSTNAME} ]]
then
    WEBY_HOSTNAME="0.0.0.0"
fi

# Create database
echo "Creating database..."
rake db:create
echo "Database created."

# Load Schema
echo "Loading database schema..."
rake db:schema:load
echo "Schema loaded."

# Run migrations
echo "Running migrations..."
bin/rails db:migrate RAILS_ENV=$RAILS_ENV
echo "Migrations completed."

# Add seed data
echo "Seeding database..."
bin/rails db:seed RAILS_ENV=$RAILS_ENV
echo "Database seeded."


rails s -b $WEBY_HOSTNAME -p 3000
