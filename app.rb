require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'sinatra/contrib/all'

class SinatraApp < Sinatra::Base
   
  enable :sessions
 
  use OmniAuth::Builder do
    provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: "user" #,repo,gist"
  end

  helpers Sinatra::ContentFor
  helpers do
    # for templates
    def blank?(o)
      o.nil? || o.empty?
    end

    def active(menukey, id)
      menukey == id ? 'class="active"' : ''
    end
  
    def menu_item(menukey, id, caption = nil)
      return "<li #{active(menukey, id.downcase.gsub(' ', '_'))}><a href=\"/#{id.downcase.gsub(' ', '_')}\">#{caption || id}</a></li>"
    end
  
    def expand_if(id, menu)
      id == menu && " in"
    end
  end

  helpers do    
    # for auth
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
        :layout => {
          menukey: code.to_s,
          show_menu: false,
          show_user: false,
          show_header: false,
          show_footer: false,
          is_dialog: true,
          body_tag: "http-error"
        },
        :error => { 
          code: code,
          message: message
        }
      }
      status code.to_i
      halt erb(:error, :layout => :layout, :locals => locals)
    end
  end
  
  
  get "/error/:code" do
    code = params[:code]
    error_page code
  end


#  get '/' do 
#    require_auth
#    locals = { 
#      :current_user => current_user, 
#      :layout => { 
#        :header_text => "Dashboard", 
#        :menu_expand => "dashboard"
#      }
#    }
#    erb :index, :layout => :layout, :locals => locals
#  end
  
  
  routes = {
    :public => {
      :faq => {
        menukey: "faq", 
        header_text: "FAQ"
      },
      :help => { 
        menukey: "help", 
        header_text: "Help"     
      },
      :privacy_policy => {
        menukey: 'privacy_policy',
        header_text: 'Privacy Policy',
        menu_expand: 'legal'
      },
      :reset_password => {
        menukey: "reset_password",
        show_menu: false,
        show_user: false,
        show_footer: false,
        is_dialog: true
      },
      :sign_in => {
        menukey: "sign_in",
        show_menu: false,
        show_user: false,
        show_footer: false,
        is_dialog: true 
      },
      :sign_up => {
        menukey: "sign_up",
        show_menu: false,
        show_user: false,
        show_footer: false,
        is_dialog: true 
      },
      :terms_and_conditions => {
        menukey: 'terms_and_conditions',
        header_text: 'Terms and Conditions',
        menu_expand: 'legal'
      }
    },
    :normal => {
      :index => {}, 
      :media => {
        menukey: "media",
        header_text: "Media"
      }
    },
    :admin => {
      :calendar => {
        menukey: "calendar",
        header_text: "Calendar"
      },
      :user => {
        menukey: "user",
        header_text: "Edit User"
      },
      :users => {
        menukey: "users",
        header_text: "Users"
      }
    }
  }

  routes.each do |scope, endpoints|
    endpoints.each do |key, vars| 
      get "/#{key.to_s unless key == :index}" do
        require_auth if scope != :public
        require_admin if scope == :admin
        locals = {
          :current_user => current_user, 
          :layout => { 
            :header_text => "Dashboard",
            :menu_expand => "dashboard"
          }.merge(vars),
        }
        erb key, :layout => :layout, :locals => locals
      end 
    end
  end
  
  get "/auth/:provider/callback" do 
    oauth_callback
  end
  
  post "/auth/:provider/callback" do 
    oauth_callback
  end
  
  def oauth_callback
    auth_hash = request.env["omniauth.auth"]
    session[:user] = {
      :uid => auth_hash[:uid],
      :nickname => auth_hash[:info][:nickname],
      :email => auth_hash[:info][:email],
      :access_token => auth_hash[:credentials][:token],
      :provider => :github,
      :admin => is_github_admin?(auth_hash[:credentials][:token])
    }
 
    redirect '/'
  end

  ["/sign_in/?", "/signin/?", "/log_in/?", "/login/?", "/sign_up/?", "/signup/?"].each do |path|
    get path do
      locals = {
        :layout => {
          show_menu: false,
          show_user: false,
          show_footer: false,
          is_dialog: true 
        }
      }
      erb :sign_in, :layout => :layout, :locals => locals   
    end
  end

  ["/sign_in/?", "/signin/?", "/log_in/?", "/login/?", "/sign_up/?", "/signup/?"].each do |path|
    post path do
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
        :admin => false
      }
      session[:user][:admin] = is_admin? session[:user]
      redirect '/'
    end
  end
  
  def is_admin?(user)
    case user[:provider]
    when :internal
      user[:email].downcase == "admin@domain.com"
    when :github
      is_github_admin? user[:access_token]
    else
      false
    end
  end

  def is_github_admin?(token)
    team_id = ENV['GITHUB_TEAMID']
    return true unless team_id
    
    github = Github.new :oauth_token => token

    begin
      team = github.orgs.teams.get team_id
      true
    rescue Github::Error::GithubError => e
      puts e.message
      false
    end
  end

  def validate_creds(email, pass)
    # replace this is some real password magic
    creds = [{email: "admin@domain.com", pass: "admin"}, {email: "user@domain.com", pass: "user"}]
    creds.each do |user|
      return true if user[:email].downcase == email.downcase && user[:pass] == pass
    end
    false
  end
  
  # either /log_out, /logout, /sign_out, or /signout will end the session and log the user out
  ["/sign_out/?", "/signout/?", "/log_out/?", "/logout/?"].each do |path|
    get path do
      session[:user] = nil
      redirect '/'
    end
  end
end  

SinatraApp.run! if __FILE__ == $0
