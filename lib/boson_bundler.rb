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

    # This will load the bundle called "bundle" and run the ruby command "command", using argv as the arguments
    # This function will import the execution of command into the current process.  This creates some interesting
    # effects.  It allows you to add/remove/monkey-patch the system before "command" is loaded and ran.
    # Whether this function returns or not is dependant on implementation details of "command"
    def self.run(bundle, command, argv = Array.new())
        setup(bundle)
        original_argv = ARGV.dup
        begin
            version = ">= 0"
            ARGV.replace argv if argv != nil
            gem_name = bundle 

            gem gem_name, version
            load Gem.bin_path(gem_name, command, version)
        ensure
            # always restore our ARGV
            ARGV.replace original_argv
        end
    end
end

