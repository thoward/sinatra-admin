require 'bundler/setup'
Bundler.require

require 'lib/auth'

module Admin
  module Auth
    module Github
      def self.registered(app)

        app.use OmniAuth::Builder do
         provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], :scope =>"user" #,repo,gist"
        end

        app.get "/auth/:provider/callback" do 
          oauth_callback
        end
    
        app.post "/auth/:provider/callback" do 
          oauth_callback
        end
        Admin::Auth.register :github
      end

      def oauth_callback
        auth_hash = request.env["omniauth.auth"]
        session[:user] = {
          :uid => auth_hash[:uid],
          :nickname => auth_hash[:info][:nickname],
          :email => auth_hash[:info][:email],
          :access_token => auth_hash[:credentials][:token],
          :provider => :github,
          :admin => is_github_admin?(auth_hash[:credentials][:token]),
          :settings_url => "https://github.com/settings/profile"
        }
     
        redirect '/'
      end

      def is_github_admin?(token)
        team_id = ENV['GITHUB_TEAMID']
        return true unless team_id
        
        github = ::Github.new :oauth_token => token

        begin
          team = github.orgs.teams.get team_id
          true
        rescue Github::Error::GithubError => e
          puts e.message
          false
        end
      end
    end
  end
end