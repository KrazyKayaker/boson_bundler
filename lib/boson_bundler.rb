#
# Author:: Ryan Kraay (<r.kraay@kurses.com>)
# Copyright:: Copyright (c) 2011 Ryan Kraay
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module BosonBundler
	#Often we need to include bundled gems -- this function will provide us with a consistant method of doing that
	# In the event that a bundled gem is either out of date or not installed, it'll automatically install the bundled
	# gems and relaunch this process.  Unfortunately, running Bundler.setup -> bundle install -> Bundler.setup doesn't
	# work, thus we have to rely on special exit codes (200) to communicate to a monitoring shell script that the command
    # needs to be re-ran
	def self.setup_path(path)
        # we intentionally delay the loading of bundler, because the boson command *may* want to
        # load things (ie: change the yaml parser from syck to psych) *before* bundler does it's thing
        require 'bundler'

		Dir.chdir(path) do
			# Bundler.setup even if it fails will corrupt our environment to the point
			# that bundler.exe won't run.	Oddly this only seems to happen when we 
			# upgrade an existing bundler deployment
			env = ENV.to_hash.dup
			begin
				Bundler.setup
			rescue => failure
				#puts failure.backtrace.join("\n")
				puts failure.to_s
				puts "Attempting to redeploy..."
				ENV.replace env
				unless system('bundle install --path vendor/bundle --deployment') then
					puts "Failed to launch bundle install"
					exit 201
				else
					xit = $?
					# returning back a status of 200 will tell the shell script to relaunch this command
					exit (xit.exitstatus == 0) ? 200 : xit.exitstatus
				end
			end
		end if File.exist?(File.join(path, "Gemfile"))
		#now we'll add the lib directory if it exists
		begin
			lib_path = File.join(path, "lib")
			$:.unshift lib_path if File.exist?(lib_path)
		end
	end

    # This is just a simple courtsey wrapper around setup_path which provides a default path to the bundles
    def self.setup(bundle)
        setup_path(File.expand_path("../../bundles/#{bundle}", __FILE__))
    end

    # This will load "version" of "gem_name" and run "command", using "argv" as the arguments.
    # Another way of explaining this is that it will import "command" and run it within the context of the
    # current process.  This creates some interesting effects:  It allows you to add/remove/monkey-patch your process
    # *before* "command" is loaded and ran.  Since this is all happening within the same ruby process globals, functions,
    # class definitions, ect can all be shared.  It also allows you to run arbitrary code *after* command has finished (see warning below)
    #
    # WARNING:  Most "command" were not written to be invoked this way, so there maybe side-effects.  In addition this 
    # function offers *no* seatbelts (read eval() is not used).
    #
    # Example: 
=begin
    module Chef
        # (Re-)Configures the machine in an idempotant way
        def chef
            #load in the support library
            require 'boson_bundler'
            #imports the bundles/chef gems
            BosonBundler.setup 'chef'
    
            # does the same as: "bundle exec chef-solo --help", but only from
            # within the current process
            BosonBundler.bin_path 'chef', 'chef-solo', %w( --help )
        end
    end
=end
    def self.bin_path(gem_name, command, argv = Array.new(), version = ">= 0")
        original_argv = ARGV.dup
        begin
            ARGV.replace argv if argv != nil

            gem gem_name, version
            load Gem.bin_path(gem_name, command, version)
        ensure
            # always restore our ARGV
            ARGV.replace original_argv
        end
    end
end

