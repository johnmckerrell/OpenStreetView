class Api::PhotosController < Api::ApplicationController
  before_filter :login_required, :except => [ :locate ]
  around_filter :catch_errors

  def moderation_count
    @result = { :count => Photo.moderation_count(current_user) }
    render_json
  end

  def request_more
    if request.post?
      # FIXME Only try to add photos that don't already have this user
      # as a moderator by selecting the photo IDs in this stage and
      # then selecting the photos not in the selection of IDs in the next
      # stage.
      existing_count = Moderator.count(
        :conditions => [ "moderators.user_id = ? AND moderators.status = 'pending' AND photos.status = 'moderation'", current_user.id ],
        :include => [ :photo ] )
      if existing_count < MAX_USER_MODERATORS
        request_count = MAX_USER_MODERATORS - existing_count
        photo_ids = ActiveRecord::Base.connection.select_all( "SELECT DISTINCT p.id FROM photos p LEFT OUTER JOIN moderators m ON m.photo_id = p.id WHERE p.status = 'moderation' AND ( m.id IS NULL OR m.user_id <> #{@current_user.id}) ORDER BY RAND() LIMIT #{request_count}" )
        photo_ids.map! { |p| p['id'] }
        photos = Photo.find( :all,
          :conditions => "id IN ( #{photo_ids.join(',')} )" )
        added = []
        photos.each do |p|
          if p.add_moderator( current_user )
            added.push(p)
          end
          if existing_count + added.length >= MAX_USER_MODERATORS
            break
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
