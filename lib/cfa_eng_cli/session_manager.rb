# frozen_string_literal: true

module CfaEngCli
  # Wrapper for session-manager-plugin.
  class SessionManager
    # Initialize a new SessionManager instance.
    #
    # @param session [Aws::SSM::Types::StartSessionResponse] The session object
    #   containing session details.
    def initialize(session)
      @session = session
    end

    # Opens a session using the session-manager-plugin.
    #
    # @param target [SessionTarget] The target of the connection.
    def open(target)
      session = {
        SessionId: @session.session_id,
        StreamUrl: @session.stream_url,
        TokenValue: @session.token_value
      }.to_json
      params = {
        Target: target.id
      }.to_json

      exec('session-manager-plugin', session, target.region, 'StartSession',
           target.profile, params, "https://ssm.#{target.region}.amazonaws.com")
    end
  end
end
