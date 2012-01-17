#!/usr/bin/env bash
#
# ./bb - a CLI for boson_bundler
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

source /etc/profile
source /usr/local/rvm/scripts/rvm
self=$(readlink -f $0)
bin_dir=`dirname $self`
bb_cmd="${bin_dir}/lib/bb --backtrace"
${bb_cmd} "$@"
# This use of 'xit' is necessary, because after our conditional $? is replaced
xit=$?
if [ $xit == 200 ]; then
  echo "$0: Detected failure in bundled Gems, attempting to correct..."
  ${bb_cmd} "$@"
  xit=$?
fi
exit $xit
