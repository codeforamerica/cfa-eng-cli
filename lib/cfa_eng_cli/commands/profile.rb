# frozen_string_literal: true

require 'thor'

require_relative '../config/profile'

module CfaEngCli
  module Commands
    # Commands for managing profiles.
    class Profile < Thor
      desc 'create', 'Create a new profile.'
      option :name, type: :string, desc: 'Name of the profile'
      option :project, type: :string, desc: 'Project to associate with the profile'
      option :environment, type: :string, desc: 'Environment to associate with the profile'
      option :aws_profile, type: :string, desc: 'AWS profile to use for credentials'
      option :region, type: :string, desc: 'Primary region for the project'
      def create
        Config::Profile.options.each do |name, opts|
          next if options[name]

          value = ask("#{opts[:prompt]} [#{opts[:default] if opts[:default]}]:")
          options[name] = value.empty? ? opts[:default] : value
        end

        Config::Profile.new(options).write
      end

      desc 'delete PROFILE', 'Delete a local profile.'
      option :yes, type: :boolean, default: false,
                   desc: 'Delete profile without prompting for confirmation'
      def delete(name)
        return unless options[:yes] || yes?("Permanently delete profile '#{name}'?")

        Config::Profile.delete(name)
        say("Profile #{name} deleted.", :green)
      end

      desc 'list', 'List all profiles.'
      def list
        Config::Profile.list.sort.each do |profile|
          say(profile)
        end
      end

      desc 'rename PROFILE NAME', 'Rename a profile.'
      option :yes, type: :boolean, default: false,
                   desc: 'Rename profile without prompting for confirmation'
      def rename(profile, name)
        return unless options[:yes] || yes?("Rename profile '#{profile}' to '#{name}'?")

        Config::Profile.load(profile).rename(name)
        say("Profile renamed to #{name}.", :green)
      end
    end
  end
end
