#!/usr/bin/env ruby

require "dotenv/load"
require "active_support/all"
require "json"
require "octokit"
require "aws-sdk-s3"
require "fileutils"
require "date"
require "faraday"

Dir["./lib/**/*.rb"].sort.each { |f| require f }

BackupRunner.run