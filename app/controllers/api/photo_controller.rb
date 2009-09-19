class Api::PhotoController < Api::ApplicationController
before_filter :login_required
around_filter :catch_errors
#around_filter :output_json

before_filter :load_photo


  def load_photo
    begin
      @photo = Photo.find(params[:id])
      @photo.set_moderator(current_user)
    rescue ActiveRecord::RecordNotFound
      raise APIError.new("Record not found",404)
    end
  end

  def index
    @result = @photo
    render_json
  end

  def mask
    if request.post?
      moderator = Moderator.find(:first, :conditions => {
          :user_id => current_user.id,
          :photo_id => params[:id] } )
      if moderator.nil?
        raise APIError.new("Unauthorised",401)
      end
      tags = Tag.from_json(request.raw_post)
      tags.each do |t|
        if t.id and t.deleted_at
          existing = Tag.find(t.id)
          existing.deleted_at = Time.now
          existing.deleting_user = current_user
          existing.save!
        else
          t.mask_tag = true
          t.photo = @photo
          t.user = current_user
          t.save!
        end
      end
      @photo.update_mask
      load_photo
      @result = @photo
    end
    render_json
  end

  def tag
    if request.post?
      tags = Tag.from_json(request.raw_post)
      tags.each do |t|
        if t.id and t.deleted_at
          existing = Tag.find(t.id)
          existing.deleted_at = Time.now
          existing.deleting_user = current_user
          existing.save!
        else
          t.mask_tag = false
          t.photo = @photo
          t.user = current_user
          t.save!
        end
      end
      # Not updating here as it's not fundamental
      load_photo
      @result = @photo
    end
    render_json
  end

  def metadata
    if request.post?
      json = JSON.parse(request.raw_post)
      md = CompositeMetaData.find(:first, :conditions => {
          :user_id => current_user.id,
          :photo_id => params[:id] } )
      if md.nil?
        md = md.new(json)
        md.save!
      else
        md.update_attributes!(json)
      end
    end
    render_json
  end

  def moderate
    if request.post?
      moderator = Moderator.find(:first, :conditions => {
          :user_id => current_user.id,
          :photo_id => params[:id] } )
      json = JSON.parse(request.raw_post)
      if moderator.status != 'safe' and json['status'] and json['status'] != ''
        moderator.status = json['status']
        moderator.save!
        if moderator.status == 'safe'
          @photo.update_safeness
        end
      end
      load_photo
      @result = @photo
    # FIXME - Raise the 405 but set the allow header too, somehow
    #else
      #raise APIError.new("Incorrect method", 405)
    end
    render_json
  end

end
