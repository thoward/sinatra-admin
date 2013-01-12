require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'sinatra/contrib/all'

require 'lib/templates'
require 'lib/error_page'

module Admin
  module Auth
    def current_user
      session[:user]
    end

    def signed_in? 
      nil != current_user
    end

    def require_auth
      redirect '/sign_in' unless signed_in?
    end

    def require_admin
      require_auth
      error_page 401 unless current_user[:admin]
    end

    @@providers = []
    def self.register(provider)
      providers.push(provider)
    end

    def self.providers
      @@providers
    end

    def self.registered(app)
      app.route_for :sign_in, :public, { :show_menu => false, :show_user => false, :show_footer => false, :is_dialog => true }

      app.get "/sign_out" do
        session[:user] = nil
        redirect '/'
      end
    end
  end
end