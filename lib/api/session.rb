module API
  class Session < Grape::API
    helpers do
      def login_counter
        @login_counter ||= Gitlab::Metrics.counter(:user_session_logins_total, 'User sign in count')
      end

      def log_audit_event(user, resource, options = {})
        Gitlab::AppLogger.info("Successful Login: username=#{resource.username} ip=#{env["REMOTE_ADDR"]} method=#{options[:with]} admin=#{resource.admin?}")
        AuditEventService.new(user, user, options)
          .for_authentication.security_event
      end

      def log_user_activity(user)
        login_counter.increment
        ::Users::ActivityService.new(user, 'login').execute
      end

      def authentication_method
        "api"
      end
    end

    desc 'Validates a username or email + password combination.' do
      success Entities::User
    end
    params do
      optional :login, type: String, desc: 'The username'
      optional :email, type: String, desc: 'The email of the user'
      requires :password, type: String, desc: 'The password of the user'
      at_least_one_of :login, :email
    end
    post "/session" do
      user = Gitlab::Auth.find_with_user_password(params[:email] || params[:login], params[:password])

      return unauthorized! unless user
      return render_api_error!('401 Unauthorized. You have 2FA enabled. Please use a personal access token to access the API', 401) if user.two_factor_enabled?

      log_audit_event(user, user, with: authentication_method)
      log_user_activity(user)

      present user, with: Entities::User
    end
  end
end
