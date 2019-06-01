# frozen_string_literal: true

# Cloud Foundry Java Buildpack
# Copyright 2013-2016 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/util'
require 'digest'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch Safenet ProtectApp Java Security Provider support.
    class SnykDemo < JavaBuildpack::Component::BaseComponent
      include JavaBuildpack::Util

      def detect
        self.class.to_s.dash_case
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        foo = (@application.root + '**/*.jar').glob[0]

        puts "DIM this is a test"
        i = 0
        puts "DIM#{i+=1} #{foo.class}"
        puts "DIM#{i+=1} #{foo.instance_variables}"
        puts "DIM#{i+=1} #{foo.public_methods}"
        puts "DIM#{i+=1} #{foo.to_s}"
        hash = Digest::SHA1.file foo.to_s
        puts "DIM#{i+=1} #{hash}"

        url = "http://search.maven.org/solrsearch/select?q=1:#{hash}&wt=json&rows=20"
        response = HTTParty.get(url)
        puts "DIM#{i+=1} #{response.code}"
        puts "DIM#{i+=1} #{response.body}"
        resp = JSON.parse(response.body)
        puts "DIM#{i+=1} #{resp}"
        puts "DIM#{i+=1} #{resp.as_json}"
        puts "DIM#{i+=1} #{resp.to_json}"
        raise "DIM error!"
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release

      end

      private

    end
  end
end
