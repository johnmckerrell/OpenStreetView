# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  # FIXME implement this
  def admin_required
    redirect_to :controller => 'sessions', :action => 'new'
    #if current_user.nil? || current_user.login != 'john'
    #end
  end

end
