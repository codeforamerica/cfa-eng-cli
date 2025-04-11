# frozen_string_literal: true

require 'configsl'

module CfaEngCli
  module Config
    # Profile definition.
    class Profile < ConfigSL::Config
      class InvalidProfile < Thor::Error; end

      register_file_format :yaml

      option :name, type: String, required: true
      option :project, type: String, required: true
      option :environment, type: String, required: true
      option :aws_profile, type: String, reguired: true
      option :region, type: Symbol, required: true,
                      enum: %i[us-east-1 us-east-2 us-west-1 us-west-2]

      def self.load(name)
        profile = from_file(File.join(Dir.home, '.codeforamerica/profiles', "#{name}.yaml"))
        profile.validate!
        profile
      rescue Errno::ENOENT
        raise InvalidProfile, "Invalid profile '#{name}'"
      end
    end
  end
end
