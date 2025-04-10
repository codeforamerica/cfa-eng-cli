# frozen_string_literal: true

module CfaEngCli
  # Represesnts the target of an SSM session.
  class SessionTarget
    attr_reader :id, :region, :profile

    def initialize(id, region, profile)
      @id = id
      @region = region
      @profile = profile
    end
  end
end
