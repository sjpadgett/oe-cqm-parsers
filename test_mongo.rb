#!/usr/bin/env ruby

# Simple test script to verify MongoDB connectivity
require 'mongoid'

begin
  # Load configuration
  Mongoid.load!('config/mongoid.yml', ENV['RAILS_ENV'] || 'development')
  
  # Test connection
  puts "Testing MongoDB connection..."
  puts "MongoDB URI: #{ENV['MONGODB_URI'] || 'using default (localhost:27017)'}"
  
  # Try to connect
  Mongoid.default_client.database.stats
  puts "✅ MongoDB connection successful!"
  puts "Database: #{Mongoid.default_client.database.name}"
  
rescue Exception => e
  puts "❌ MongoDB connection failed: #{e.message}"
  exit 1
end