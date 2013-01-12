require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'sinatra/contrib/all'

module Admin
  module Templates
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
end