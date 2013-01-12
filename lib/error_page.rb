require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'sinatra/contrib/all'

require 'lib/templates'

module Admin
  module ErrorPage
    def error_page(code, message=nil)
      error_messages = {
        "401" => "Not authorized",
        "403" => "Forbidden",
        "404" => "Not found",
        "500" => "Internal server error",
        "503" => "Service unavailable"
      }

      message = (message || error_messages[code.to_s] || "An error occured.")

      locals = {
        :current_user => current_user,
        :scope => :public,
        :layout => {
          :menukey => code.to_s,
          :show_menu => false,
          :show_user => false,
          :show_header => false,
          :show_footer => false,
          :is_dialog => true,
          :scope => :public,
          :body_tag => "http-error"
        },

        :error => { 
          :code => code,
          :message => message
        }
      }
      status code.to_i
      halt erb(:error, :layout => :layout, :locals => locals)
    end

    def self.registered(app)
      app.get "/error/:code" do
        code = params[:code]
        error_page code
      end
    end
  end
end