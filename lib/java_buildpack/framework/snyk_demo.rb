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
        vulns = []

        i = 0
        all_jars = (@application.root + '**/*.jar').glob
        n_failures = 0
        response = nil
        all_jars.each do |jar|
          checksum = Digest::SHA1.file jar.to_s
          puts "==================================="
          puts "DIM#{i += 1} #{checksum}"
          url = "http://search.maven.org/solrsearch/select?q=1:#{checksum}&wt=json&rows=20"
          puts "DIM#{i += 1} #{url}"
          begin
            response = Net::HTTP.get(URI(url))
          rescue => e
            @logger.warn "SnykDemo: maven query failed #{url} (#{e})"
            n_failures += 1
            if n_failures > 3
              raise "SnykDemo: too many maven query failures. Stopping process"
            end
          end
          puts "DIM#{i += 1} #{response}"
          resp = JSON.parse(response, { symbolize_names: true })
          puts "DIM#{i += 1} #{resp}"
          data = resp[:response]
          puts "DIM#{i += 1} #{data}"

          data[:docs].each do |doc|
            puts "DIM#{i += 1} #{doc}"
            group_id = doc[:g]
            artifact_id = doc[:a]
            version = doc[:v]
            url = "https://blooming-earth-53687.herokuapp.com/query?groupId=#{group_id}&artifactId=#{artifact_id}&version=#{version}"
            @logger.info "querying vulnerabilities for jar #{group_id}, #{artifact_id}, #{version}"
            puts "DIM#{i += 1} #{url}"
            begin
              response = Net::HTTP.get(URI(url))
            rescue => e
              @logger.warn "vulnerabilities query failed #{url} (#{e})"
              n_failures += 1
              if n_failures > 3
                raise "SnykDemo: too many maven query failures. Stopping process"
              end
            end

            if response != "OK"
              resp = JSON.parse(response, { symbolize_names: true })
              puts "DIM#{i += 1} #{resp}"
              vulns << [{ group_id: group_id, artifact_id: artifact_id, version: version, cve: resp[:cve] }]
            end
          end


        end


        if vulns.length > 0
          @logger.error "Found #{vulns.length} vulnerable packages"
          vulns.each_with_index do |v, index|
            @logger.error "#{index + 1}: #{v[:group_id]}, #{v[:artifact_id]}, #{v[:version]}, #{v[:cve]}"
          end
          raise "SnykDemo: found #{vulns.length} vulnerable packages"
        else
          @logger.info "Found 0 vulnerable packages"
        end

        raise "FAIL ME"
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release

      end

      private

    end
  end
end
