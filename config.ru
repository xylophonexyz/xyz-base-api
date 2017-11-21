# This file is used by Rack-based servers to start the application.
require 'dotenv'
require ::File.expand_path('../config/environment', __FILE__)
Dotenv.load
run Rails.application
