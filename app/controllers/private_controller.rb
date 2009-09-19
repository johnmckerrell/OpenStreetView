class PrivateController < ApplicationController
  before_filter :login_required

  def index
    status = params[:path][0]
    fn = params[:path][1]
    matches = fn.match( /(.*)(-[a-z]+).jpg/ )
    if status and status != '' and matches
      p = Photo.find_by_filename( matches[1] )
      allowed = false
      if p 
        # Users can always view their own photos
        if p.user_id == current_user.id
          allowed = true
        # Moderators can only view photos in moderation status
        # In case the user takes the photos back to unavailable
        elsif p.status = 'moderation'
          m = Moderator.count( :conditions => { :user_id => current_user.id, :photo_id => p.id } )
          if m > 0
            allowed = true
          end
        end
        if allowed
          begin
            send_file "private/#{status}/#{fn}"
            return
          rescue StandardError
          end
        elsif p
          render :text => "Unauthorized", :status => 401
          return
        end
      end
    end

    # If we haven't rendered something already, assume there's a problem
    render :text => "File not found", :status => 404
  end
end
