class Api::PhotosController < Api::ApplicationController
  before_filter :login_required, :except => [ :locate ]
  around_filter :catch_errors

  def moderation_count
    @result = { :count => Photo.moderation_count(current_user) }
    render_json
  end

  def request_more
    if request.post?
      existing_count = Moderator.count(
        :conditions => [ "user_id = ? AND status = 'pending'", current_user.id ] )
      if existing_count < MAX_USER_MODERATORS
        request_count = MAX_USER_MODERATORS - existing_count
        photos = Photo.find( :all,
          :conditions => "status = 'moderation'",
          :limit => request_count,
          :order => "RAND()" )
        added = []
        photos.each do |p|
          if p.add_moderator( current_user )
            added.push(p)
          end
        end
      end
      @result = added
    end
    render_json
  end

  def locate
    @result = Photo.find_in_area(params[:bbox])
    render_multiformat
  end

  def unlocated
    @result = Photo.find_unlocated(params)
    render_multiformat
  end

  def index
    @result = Photo.find_for_status(params, current_user)
    render_json
  end
end
