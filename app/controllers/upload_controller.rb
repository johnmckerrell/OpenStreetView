class UploadController < ApplicationController
  before_filter :login_required

  def index
    if request.method == :post and params[:file]
      im = MiniMagick::Image.new(params[:file].path)
      if im['format'] != 'JPEG'
        flash[:error] = 'We can only accept JPEG images at this time.'
      else
        pb = PhotoBatch.new
        pb.user = current_user
        pb.name = params[:file].original_filename
        pb.save
        if Photo.handle_file( params[:file], current_user, pb )
          flash[:notice] = "File Uploaded"
          redirect_to :action => 'index'
        end
      end
    end
  end

  def ftp_process
    fl = FtpLogin.find_by_user_id( current_user.id )
    process = params[:process]
    if fl
      message = fl.process( process )
      if message and message != ""
        flash[:error] = message
      end
    end
    redirect_to :action => 'ftp'
  end

  def ftp_create
    fl = FtpLogin.find( :first, :conditions => { :user_id => current_user.id } )
    if fl.nil? and params[:create] == 'yes'
      fl = FtpLogin.new( @current_user )
      fl.save
    end
    redirect_to :action => 'ftp'
  end

  def ftp
    @fl = FtpLogin.find( :first, :conditions => { :user_id => current_user.id } )
    if @fl
      @path = @fl.path
      @subdir = nil
      @subdir_contents = nil
      if params[:subdir]
        @subdir = File.basename(params[:subdir])
        if @subdir == '.' or @subdir == '..'
          @subdir = ''
        end
        if @subdir != ''
          @subdir_contents = Dir.entries( @path+'/'+@subdir )
          @subdir_contents = @subdir_contents.reject { |d| d == '..' or d == '.' }
        end
      end
      @dir_contents = Dir.entries( @path )
      @dir_contents = @dir_contents.reject { |d| d == '..' or d == '.' }
    else
      @dir_contents = nil
    end
  end
end
