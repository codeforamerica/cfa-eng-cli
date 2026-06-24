# frozen_string_literal: true

require_relative 'base'

module CfaEngCli
  module Config
    # Doppler configuration nested within a profile.
    class Doppler < Base
      option :project, type: String, required: false, default: 'shared-services',
                       prompt: 'Doppler project'
      option :environment, type: String, required: false, default: 'infra',
                           prompt: 'Doppler environment name without any branch suffixes'
    end
  end
end
