#!/usr/bin/env ruby

require 'rubygems'
require 'boson'

# Monkey-patch the local repo, so it's relative to this file
module Boson
    def local_repo
        # Repo.new will automatically append ./commands to all the directories
        Repo.new(File.dirname(__FILE__))
    end
end

require 'boson/runners/bin_runner'

Boson::BinRunner.start
