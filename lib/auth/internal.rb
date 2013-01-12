require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'sinatra/contrib/all'

require 'lib/auth'

module Admin
  module Auth
    module Internal
      def is_internal_admin?(user)
        user[:email].downcase == "admin@domain.com"
      end

      def validate_creds(email, pass)
        # replace this is some real password magic
        creds = [{:email => "admin@domain.com", :pass => "admin"}, {:email => "user@domain.com", :pass => "user"}]
        creds.each do |user|
          return true if user[:email].downcase == email.downcase && user[:pass] == pass
        end
        false
      end

      def self.registered(app)
        app.route_for :reset_password, :public, { :show_menu => false, :show_user => false, :show_footer => false, :is_dialog => true }
        app.route_for :sign_up, :public, { :show_menu => false, :show_user => false, :show_footer => false, :is_dialog => true }

        app.post "/sign_in" do
          email = params["email"]
          pass = params["password"]
          remember = params["remember"] ? true : false
          
          error_page 401 unless validate_creds(email, pass)

          session[:user] = {
            :uid => email,
            :nickname => email,
            :email => email,
            :access_token => email,
            :provider => :internal,
            :admin => false,
            :settings_url => nil
          }

          session[:user][:admin] = is_internal_admin? session[:user]
          redirect '/'
        end

        Admin::Auth.register :internal
      end
    end
  end
end