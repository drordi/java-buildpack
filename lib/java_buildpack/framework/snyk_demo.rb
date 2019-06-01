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
require 'net/http'

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
        @logger = JavaBuildpack::Logging::LoggerFactory.instance.get_logger SnykDemo

        i = 0
        all_jars = (@application.root + '**/*.jar').glob
        n_failures = 0
        all_jars.each do |jar|
          checksum = Digest::SHA1.file jar.to_s
          puts "==================================="
          puts "DIM#{i+=1} #{checksum}"
          url = "http://search.maven.org/solrsearch/select?q=1:#{checksum}&wt=json&rows=20"
          puts "DIM#{i+=1} #{url}"
          begin
            response = Net::HTTP.get(URI(url))
            puts "DIM#{i+=1} #{response}"
            resp = JSON.parse(response, {symbolize_names: true})
            puts "DIM#{i+=1} #{resp}"
            data = resp[:response]
            puts "DIM#{i+=1} #{data}"
            if data[:numFound] == 1
              doc = data[:docs].first
              puts "DIM#{i+=1} #{doc}"
              group_id = doc[:g]
              artifact_id = doc[:a]
              version = doc[:v]
              url = "https://blooming-earth-53687.herokuapp.com/query?groupId=#{group_id}&artifactId=#{artifact_id}&version=#{version}"
              @logger.info "SnykDemo: querying vulnerabilities for jar #{group_id}, #{artifact_id}, #{version}"
              puts "DIM#{i+=1} #{url}"
              response = Net::HTTP.get(URI(url))
              resp = JSON.parse(response, {symbolize_names: true})
              puts "DIM#{i+=1} #{resp}"
            else
              @logger.info "SnykDemo: found #{data[:numFound]} docs instead of 1. skip check."
            end

          rescue => e
            @logger.warn "SnykDemo: maven query failed #{url} (#{e})"
            n_failures += 1
            if n_failures > 3
              raise "SnykDemo: too many maven query failures. Stopping process"
            end
          end

        end

        raise "DIM error!"
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release

      end

      private

    end
  end
end
