require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'sinatra/contrib/all'

require 'lib/templates'
require 'lib/error_page'
require 'lib/auth'
require 'lib/auth/internal'
require 'lib/auth/github'
require 'lib/routing'

module Admin
  class AdminApp < Sinatra::Base
    enable :sessions

    helpers Sinatra::ContentFor

    helpers Admin::Templates

    register Admin::ErrorPage
    helpers Admin::ErrorPage

    register Admin::Routing
    
    register Admin::Auth
    helpers Admin::Auth

    register Admin::Auth::Internal
    helpers Admin::Auth::Internal

    register Admin::Auth::Github
    helpers Admin::Auth::Github

    route_for :faq, :public, { :header_text => "FAQ" }
    route_for :help, :public, { :header_text => "Help" }
    route_for :privacy_policy, :public, { :header_text => "Privacy Policy", :menu_expand => 'legal' }
    route_for :terms_and_conditions, :public, { :header_text => "Terms and Conditions", :menu_expand => 'legal'}

    route_for :index, :normal, {}
    route_for :media, :normal, { :header_text => "Media"}

    route_for :calendar, :admin, { :header_text => "Calendar"}
    route_for :user, :admin, { :header_text => "Edit User"}
    route_for :users, :admin, { :header_text => "Users"}
  end
end

AdminApp.run! if __FILE__ == $0
