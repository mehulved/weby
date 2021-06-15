#!/bin/bash

set -e

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
bin/rails db:migrate RAILS_ENV=development
echo "Migrations completed."

# Add seed data
echo "Seeding database..."
bin/rails db:seed RAILS_ENV=development
echo "Database seeded."


rails s -b 0.0.0.0 -p 3000
