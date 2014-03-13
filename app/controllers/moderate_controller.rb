class ModerateController < ApplicationController
  before_filter :login_required

  def request_photos
    existing_count = Moderator.count( 
      :conditions => [ "user_id = ? AND status = 'pending'", current_user.id ] )
    if existing_count < MAX_USER_MODERATORS
      request_count = MAX_USER_MODERATORS - existing_count
      photos = Photo.find( :all,
        :conditions => "status = 'moderation'",
        :limit => request_count,
        :order => "RAND()" )
      count_added = 0
      photos.each do |p|
        if p.add_moderator( @current_user )
          count_added += 1
        end
      end
      if count_added == 0
        flash[:error] = "No more photos available for moderation."
      end
    else
      flash[:error] = "You may only moderate #{MAX_USER_MODERATORS} photos at a time, please moderate some of your existing photos first."
    end
    redirect_to :action => 'index'
  end
  
  def index
    @title = "OSV: Image Moderation"
    @pageid = 'moderation'
    # jquery/jquery-1.3.2.min.js = http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js
    # jquery/jquery.ui-1.7.2.min.js = http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js
    @javascripts = [ 'jquery/jquery-1.3.2.min.js', 'jquery/jquery.ui-1.7.2.min.js', 'jquery/jquery.json-2.2.min', 'jquery/boxer.js', 'OSV', 'OSVModerator', 'OSVPhoto', 'OSVTaggingArea' ]
    #@moderators = Moderator.find( :all,
    #  :conditions => [ "user_id = ? AND status = 'pending'", current_user.id ],
    #  :include => [ :photo ] )
  end
end
