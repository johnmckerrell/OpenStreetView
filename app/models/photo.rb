class Photo < ActiveRecord::Base
  belongs_to :user
  belongs_to :photo_batch
  belongs_to :license
  has_many :tags
  has_many :moderators
  has_many :composite_metadatas
  has_many :unsafe_flags

  attr_accessor :current_moderator

  def self.handle_file( file, user, batch, options = {})
    p = Photo.new
    p.approval_needed = MIN_APPROVALS
    p.photo_batch = batch
    p.user = user
    p.status = 'handling'
    p.license = user.default_license
    # DB won't allow empty filename
    p.filename = 'temp'
    p.save

    fn = p.gen_filename
    
    path = "private/pending/"+fn
    File.open(path, "wb") { |f| f.write(file.read) }

    p.status = 'pending'
    p.filename = fn
    p.save
    fn
  end

  def set_moderator(u)
    #@current_moderator = self.moderators.find(u.id)
    #@current_moderator = self.moderators.find(:first, :conditions => { :user_id => u.id } )
    @current_moderator = nil
    puts "setting moderator for user #{u.id} and photo #{self.id}"
    self.moderators.each do |m|
      puts "checking m.user_id=#{m.user_id} against u.id=#{u.id}"
      if m.user_id == u.id
        @current_moderator = m
        return
      end
    end
  end

  # potentially pushes the image live
  def update_safeness
    # Start by getting the count of moderators that have marked the
    # photo as safe and unsafe
    approval_count = self.moderators.count(:conditions => {:status => 'safe'})
    disapproval_count = self.moderators.count(:conditions => {:status => 'unsafe'})
    # set this on the object now as it's a valid value
    self.approval_count = approval_count

    # get the moderator entry for the owner, if there is one
    # (owner doesn't always moderate their own photos)
    cm = @current_moderator
    set_moderator(self.user)
    owner_moderator = @current_moderator
    @current_moderator = cm

    puts "owner moderator is #{owner_moderator.inspect}"
    # If the owner has moderated their own image and marked it unsafe
    # then delete straight away
    if owner_moderator and owner_moderator.status == 'unsafe'
      self.update_status( 'deleted' )
    # If too many people have marked the image as unsafe then delete it
    elsif disapproval_count >= MIN_APPROVALS
      self.update_status( 'deleted' )
    # If enough people have marked the image as safe then make it available
    elsif self.status != 'available' and self.approval_count >= self.approval_needed
      self.update_status( 'available' )
    # Otherwise just save the approval count and do nothing else
    else
      # This largely here to fix a bug where any photo moderated by its owner 
      # got deleted. So if a photo was moderated by its owner and has
      # deleted status then we update its status to moderation.
      if owner_moderator and self.status == 'deleted'
        self.update_status( 'moderation' )
      else
        puts "Should be saving the approval count here: #{self.approval_count}"
        self.save!
      end
    end
  end

  # generates a new image
  def update_mask
    # Resize the original down to the large size
    # Apply any masks
    resize( 'original', self.filename, 'large', PHOTO_SIZES['large'] )

    # Resize the large size down to the other sizes
    PHOTO_SIZES.each do |type,size|
      if type == 'large'
        # Do nothing
      elsif type == 'square'
        resize( 'large', self.filename, type, size, true )
      else
        resize( 'large', self.filename, type, size )
      end
    end

    # Move these images from processing to pending
    PHOTO_SIZES.each do |type, size|
      FileUtils.move( sys_filename("processing", filename, type), sys_filename("processed", filename, type) )
    end
    if self.status == 'available'
      # This should basically only happen if someone still had a file
      # assigned as to them for moderating when someone else marked
      # it as safe and it went out. For now we'll allow this and
      # will recopy the files, we might want to stop this from 
      # happening by stopping the mask from being added in the
      # first place.
      copy_files
    end
  end

  def self.find_unlocated(params = {})
    limit = API_PHOTO_PAGE_SIZE
    offset = 0
    if params[:page].to_i != 0
      offset = API_PHOTO_PAGE_SIZE * ( params[:page].to_i - 1 )
    end
    Photo.find( :all,
      :conditions => [ "(lat IS NULL OR lon IS NULL) AND status = 'available'" ],
      :order => 'created_at ASC',
      :limit => limit,
      :offset => offset )
  end

  def self.find_in_area(bbox)
    if bbox.nil?
      return
    end
    bits = bbox.split(/,/)
    if bits.length != 4
      return
    end
    bits.map! { |b| b.to_f }
    lat_step = (bits[1] - bits[3]) / 400
    lon_step = (bits[0] - bits[2]) / 300
    Photo.find( :all,
      :conditions => [
        "lat IS NOT NULL AND lon IS NOT NULL AND lat >= ? AND lat <= ? AND lon >= ? AND lon <= ? AND status = 'available'",
        bits[1], bits[3], bits[0], bits[2] ],
      :group => [ "floor(lat/", lat_step, "), floor(lon/", lon_step, ")" ],
      :order => 'created_at DESC',
      :limit => 100 )
  end

  def self.count_for_status( status, user = nil )
    conditions = { :status => status }
    if user
      conditions[:user_id] = user.id
    end
    Photo.count( :conditions => conditions )
  end

  def self.moderation_count( user = nil )
    photos_count = Photo.count(
      :conditions => [ "status = 'moderation'" ] )
    if user
      moderated_count = Moderator.count(
        :conditions => [ "photos.status = 'moderation' AND moderators.status <> 'pending' AND moderators.user_id = ?", user.id ],
        :include => [ :photo ]
        )
      photos_count -= moderated_count
    end
    photos_count
  end

  def self.find_for_status(params,user)
    status = params[:status]
    if status.nil?
      status = 'available'
    end
    limit = API_PHOTO_PAGE_SIZE
    offset = 0
    if params[:page].to_i != 0
      offset = API_PHOTO_PAGE_SIZE * ( params[:page].to_i - 1 )
    end
    case status
    when 'moderation'
      @result = Photo.find( :all,
        :conditions => [ "moderators.user_id = ? AND moderators.status = 'pending' AND photos.status = 'moderation' ", user.id ],
        :include => [ :moderators, :tags, :composite_metadatas ],
        #:joins => [ :moderators ],
        :order => 'moderators.created_at DESC',
        :limit => limit,
        :offset => offset )
      @result.each do |r|
        r.set_moderator(user)
      end
    when 'available'
      @result = Photo.find( :all,
        :conditions => [ "status = ?", status ],
        :order => 'created_at DESC',
        :limit => limit,
        :offset => offset )
    else
      # Private photos
      @result = Photo.find( :all,
        :conditions => [ "user_id = ? AND status = ?", user.id, status ],
        :order => 'created_at DESC',
        :limit => limit,
        :offset => offset )
      #@result = Photo.private_photos(@current_user.id,params)
    end
    @result
  end

#  def to_edit_json( *a )
#    {
#      :id => id,
#      :direction => self.direction,
#      :tilt => self.tilt,
#      :lat => self.lat,
#      :lon => self.lon,
#      :status => status,
#      :taken_at => self.taken_at,
#      :created_at => self.created_at,
#      :updated_at => self.updated_at,
#      :filename => self.filename,
#      :tags => self.tags,
#      :composite_metadata => self.composite_metadatas
#    }.to_json( *a )
#  end

  def to_json( *a )
    hash = {
      :id => id,
      :tilt => self.tilt,
      :status => status,
      :taken_at => self.taken_at,
      :created_at => self.created_at,
      :updated_at => self.updated_at,
      :filename => self.filename,
      :tags => self.live_tags,
      :composite_metadata => self.composite_metadatas
    }
    if current_moderator
      hash[:moderator] = current_moderator
    end
    if lat and lon
      hash[:lat] = lat
      hash[:lon] = lon
    end
    if direction
      hash[:direction] = direction
    end
    if orientation
      hash[:orientation] = orientation
    end
    if tilt
      hash[:tilt] = tilt
    end

    hash.to_json( *a )
  end

  def live_tags
    Tag.find(:all, :conditions => { :photo_id => self.id, :deleted_at => nil })
  end

  def add_moderator( u )
    m = Moderator.find( :first, :conditions => { :photo_id => self.id, :user_id => u.id } )
    if m.nil?
      m = Moderator.new
      m.user_id = u.id
      m.photo_id = self.id
      m.save
      @current_moderator = m
      return true
    end
    return false
  end

  def process
    if self.status != 'pending' and self.status != 'processing'
      return
    end
    begin
      self.update_properties('private/pending/'+filename)
    rescue Exception
      if status == 'processing' or self.status == 'pending'
        self.status = 'error'
        self.save!
      end
      return
    end
    # Move the base file to where it will live
    FileUtils.move( sys_filename("pending", filename), sys_filename("originals", filename) )
    # Generate images from the original
    self.update_mask
    self.status = 'processing'
    update_status( 'unavailable')
  end

  def update_properties(full_filename)
    require "fileutils"
    i = EXIFR::JPEG.new(full_filename)
    self.filesize = File.size(full_filename)
    if i.exif?
      self.original_width = i.width
      self.original_height = i.height
      if i.date_time_digitized
        self.exif_taken_at = i.date_time_digitized
        self.taken_at = i.date_time_digitized
      else
        self.taken_at = Time.now
        puts "no date_time_digitized in #{i}"
      end
      latitude = parse_ll_field( i.gps_latitude, i.gps_latitude_ref )
      longitude = parse_ll_field( i.gps_longitude, i.gps_longitude_ref )
      if latitude and longitude
        self.lat = latitude
        self.lon = longitude
        self.exif_lat = latitude
        self.exif_lon = longitude
      end
      # FIXME - magnetic north or true north?
      if i.gps_img_direction
        self.direction = i.gps_img_direction.to_f
        self.exif_direction = i.gps_img_direction.to_f
        self.exif_direction_source = 'gps_img_direction'
      elsif i.gps_dest_bearing
        self.direction = i.gps_dest_bearing.to_f
        self.exif_direction = i.gps_dest_bearing.to_f
        self.exif_direction_source = 'gps_dest_bearing'
      end
      # FIXME - Add tilt from exif
    end
  end

  def update_status( new_status )
    #move_files( self.status, new_status )
    if self.status == 'available' and new_status != 'available'
      # Delete existing available files
      delete_files( 'available' )
    elsif new_status == 'available' and self.status != 'available'
      # Copy files from processed to available
      copy_files
    end
    self.status = new_status
    self.save
  end

  def url(type)
    if self.status == 'available'
      "/"+sys_filename(self.status,filename,type).gsub(/^public\//, '')
    else
      "/"+sys_filename('processed',filename,type)
    end
  end

  def gen_filename
    Digest::SHA1.hexdigest(REST_AUTH_SITE_KEY+'-'+self.id.to_s)
  end

  private
  def sys_filename( status, fn, post = nil )
    if status == 'available'
      top_dir = 'public'
    else
      top_dir = 'private'
    end
    if post.nil?
      "#{top_dir}/#{status}/#{fn}"
    else
      "#{top_dir}/#{status}/#{fn}-#{post}.jpg"
    end
  end

  def delete_files( status )
    PHOTO_SIZES.each do |type,size|
      delete_file( filename, type, status )
    end
  end

  def delete_file( fn, post, status )
    require "fileutils"
    FileUtils.safe_unlink( sys_filename(status, fn, post) )
  end

  def copy_files
    PHOTO_SIZES.each do |type,size|
      copy_file( filename, type )
    end
  end


  def copy_file( fn, post )
    require "fileutils"
    FileUtils.copy( sys_filename('processed', fn, post), sys_filename('available', fn, post) )
  end

  def resize( source, fn, post, size, crop = false )
    if source == 'original'
      source_filename = sys_filename("originals",fn)
    else
      source_filename = sys_filename("processing",fn,source)
    end
    image = MiniMagick::Image.from_file(source_filename)
    if crop
      w = image[:width]
      h = image[:height]
      if w > h
        o = ( ( w - h ) / 2 ).to_i
        image.crop "#{h}x#{h}+#{o}+0"
      else
        o = ( ( h - w ) / 2 ).to_i
        image.crop "#{w}x#{w}+0+#{o}"
      end
    end
    image.resize "#{size}x#{size}"
    if source == 'original'
      self.live_tags.each do |t|
        if t.mask_tag and t.area
          bits = t.area.split(/[x ,]/)
          puts bits.inspect
          bits.map! { |b| b.to_i }
          r = "#{bits[0]},#{bits[1]} #{bits[0]+bits[2]},#{bits[1]+bits[3]}"
          image.draw "rectangle #{r}"
          puts "Added mask of #{r}"
        end
      end
    end
    image.write(sys_filename("processing",fn,post))
  end

  def parse_ll_field( r, d )
    if r.nil?
      return r
    end
    l = r[0].to_f
    r[1] = r[1].to_f + ( r[2].to_f / 60 )
    l += r[1] / 60
    if d == 'W' || d == 'S'
      l = -l
    end
    l
  end
end
