# frozen_string_literal: true

require 'configsl'
require 'yaml'

module CfaEngCli
  module Config
    # Profile definition.
    class Profile < ConfigSL::Config
      class InvalidProfile < Thor::Error; end

      PROFILE_DIRECTORY = File.join(Dir.home, '.codeforamerica/profiles')

      register_file_format :yaml

      option :name, type: String, required: true,
                    prompt: 'Profile name'
      option :project, type: String, required: true,
                       prompt: 'Project name'
      option :environment, type: String, required: true,
                           prompt: 'Environment'
      option :aws_profile, type: String, reguired: true,
                           default: ENV.fetch('AWS_PROFILE', nil),
                           prompt: 'AWS profile'
      option :region, type: String, required: true, default: 'us-east-1',
                      enum: %w[us-east-1 us-east-2 us-west-1 us-west-2],
                      prompt: 'Primary region'

      class << self
        # Deletes a local profile.
        #
        # @param name [String] Name of the profile to delete.
        def delete(name)
          filename = File.join(PROFILE_DIRECTORY, "#{name}.yaml")
          return unless File.exist?(filename)

          File.delete(filename)
        end

        # List all local profiles.
        #
        # @return [Array<String>]
        def list
          profiles = []
          Dir.entries(PROFILE_DIRECTORY).each do |file|
            next if ['.', '..'].include?(file)

            profiles << file[0..-6]
          end

          profiles
        end

        # Loads a local prpfile.
        #
        # @param name [String] Name of the profile to load.
        # @return [self]
        def load(name)
          profile = from_file(File.join(PROFILE_DIRECTORY, "#{name}.yaml"))
          profile.validate!
          profile
        rescue ConfigSL::ValidationError, Errno::ENOENT => e
          raise InvalidProfile, "Invalid profile '#{name}': #{e.message}"
        end
      end

      # Deletes the current profile
      def delete
        Profile.delete(name)
      end

      # Renames the current profile.
      #
      # @param name [String] New name for the profile.
      # @return [Profile] New profile object.
      def rename(name)
        # Write the new profile before deleting the current one.
        profile = Profile.new(values.merge(name:))
        profile.write
        delete
        profile
      end

      # Serializes the current configuration for storage.
      #
      # @return [Hash]
      def serialize
        values.transform_keys(&:to_s)
      end

      # Writes the current configuration to a file.
      def write
        File.write(File.join(PROFILE_DIRECTORY, "#{name}.yaml"), serialize.to_yaml)
      end
    end
  end
end
