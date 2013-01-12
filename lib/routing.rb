require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'sinatra/contrib/all'

require 'lib/templates'
require 'lib/error_page'
require 'lib/auth'

module Admin
  module Routing
    def route_for(key, scope, vars)

      get "/#{key.to_s unless key == :index}" do
        require_auth if scope != :public
        require_admin if scope == :admin
        
        locals = {
          :current_user => current_user,
          :scope => scope, 
          :layout => {
            :header_text => "Dashboard",
            :menu_expand => "dashboard"
          }.merge(vars)
        }
        
        locals[:layout][:show_menu] = signed_in? unless locals[:layout][:show_menu] != nil
        locals[:layout][:show_user] = signed_in? unless locals[:layout][:show_user] != nil

        locals[:layout][:menukey] = key.to_s unless locals[:layout][:menukey]

        erb key, :layout => :layout, :locals => locals
      end
    end
  end
end