class FtpLogin < ActiveRecord::Base
  belongs_to :user

  def initialize( user=nil )
    super()
    puts "in here\n"
    username = nil
    while username.nil? or FtpLogin.find_by_username(username)
      username = 'osv'+sprintf( "%05i", rand(99999) )
    end
    self.username = username
    self.password = FtpLogin.make_token
    if user
      self.user_id = user.id
    end
    self.path = 'private/upload/'+username+'/'
    FileUtils.mkdir_p self.path
  end

  def process( items )
    other_files = [];
    batches = { }
    if items.nil?
      items = []
    end
    items.each do |entry|
      fullpath = self.path+entry
      if entry == '.' or entry == '..'
      elsif File.directory? fullpath
        batches[entry] = []
        FtpLogin.find_child_files(fullpath,batches[entry])
      elsif File.exists? fullpath
        other_files.push( fullpath )
      else
      end
    end
    count = 0
    count += self.process_batch( Time.now.to_s, other_files )
    batches.each do |n,a|
      count += self.process_batch( n, a )
      begin
        Dir.delete( self.path+n )
        # Might raise SystemCallError if directory isn't empty
        # but we just ignore that, let the user delete it
        # themselves in that case.
      end
    end
    message = ""
    if count == 0
      message = "No files found"
    end
    message
  end

  def process_batch( batch_name, files )
    if files.length == 0
      return 0
    end
    require "fileutils"
    pb = PhotoBatch.new
    pb.user = self.user
    pb.name = batch_name
    pb.save
    count = 0
    files.each do |f|
      fh = File.open(f, "r")
      fn = Photo.handle_file( fh, self.user, pb )
      fh.close
      count += 1
      FileUtils.move( f, "private/oldftpuploads/#{fn}" )
    end
    count
  end

  def self.make_token( length=10 )
    chars = 'abcdefghijklmnopqrtuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    token = ''
    length.times do
      token += chars[(rand * chars.length).to_i].chr
    end

    return token 
  end

  private
  def self.find_child_files( dir, files )
      subdir_contents = Dir.entries(dir)
      subdir_contents.each do |s|
        fullpath = dir+"/"+s
        if s == "." || s == ".."
        elsif File.directory? fullpath
          FtpLogin.find_child_files(fullpath, files)
        else
          files.push(fullpath)
        end  
      end
  end
end
