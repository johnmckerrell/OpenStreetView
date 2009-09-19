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
    p.status = 'pending'
    p.license = user.default_license
    # DB won't allow empty filename
    p.filename = 'temp'
    p.save

    fn = p.gen_filename
    p.filename = fn
    p.save
    
    path = "private/pending/"+fn
    File.open(path, "wb") { |f| f.write(file.read) }
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

  def update_safeness
    # potentially pushes the image live
    approval_count = self.moderators.count(:conditions => {:status => 'safe'})
    self.approval_count = approval_count
    if self.approval_count >= self.approval_needed
      self.update_status( 'available' )
    else
      puts "Should be saving the approval count here: #{self.approval_count}"
      self.save!
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
    Photo.find( :all,
      :conditions => [
        "lat IS NOT NULL AND lon IS NOT NULL AND lat >= ? AND lat <= ? AND lon >= ? AND lon <= ? AND status = 'available'",
        bits[0], bits[2], bits[1], bits[3] ],
      :order => 'created_at ASC',
      :limit => 100 )
  end

  def self.moderation_count
    Photo.count(
      :conditions => [ "status = 'moderation'" ] )
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
        :conditions => [ "moderators.user_id = ? AND moderators.status <> 'safe'", user.id ],
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
#      :orientation => self.orientation,
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
      :orientation => self.orientation,
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
    if self.status != 'pending'
      return
    end
    require "FileUtils"
    begin
      i = EXIFR::JPEG.new('private/pending/'+filename)
    rescue Exception
      self.status = 'error'
      self.save!
      return
    end
    if i.exif?
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
        self.orientation = i.gps_img_direction.to_f
        self.exif_orientation = i.gps_img_direction.to_f
        self.exif_orientation_source = 'gps_img_direction'
      elsif i.gps_dest_bearing
        self.orientation = i.gps_dest_bearing.to_f
        self.exif_orientation = i.gps_dest_bearing.to_f
        self.exif_orientation_source = 'gps_dest_bearing'
      end
      # FIXME - Add tilt from exif
    end
    # Move the base file to where it will live
    FileUtils.move( sys_filename("pending", filename), sys_filename("originals", filename) )
    # Generate images from the original
    self.update_mask
    self.status = 'processing'
    update_status( 'unavailable')
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
      "http://#{SERVER_URL}/"+sys_filename(self.status,filename,type).gsub(/^public\//, '')
    else
      "http://#{SERVER_URL}/"+sys_filename('processed',filename,type)
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
    require "FileUtils"
    FileUtils.safe_unlink( sys_filename(status, fn, post) )
  end

  def copy_files
    PHOTO_SIZES.each do |type,size|
      copy_file( filename, type )
    end
  end


  def copy_file( fn, post )
    require "FileUtils"
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
