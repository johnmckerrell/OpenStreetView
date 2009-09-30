class HomepageController < ApplicationController
  before_filter :login_required

  def index
    @title = "OSV: User Homepage"
    @pageid = 'user-homepage'
    counts = ActiveRecord::Base.connection.select_all( "SELECT COUNT(*) `count`, status FROM photos WHERE user_id = #{@current_user.id} GROUP BY status" )
    @counts_hash = {}
    PHOTO_STATES.each do |ps|
      @counts_hash[ps] = 0
    end
    counts.each do |c|
      @counts_hash[c['status']] = c['count'].to_i
    end
    puts "counts_hash=#{@counts_hash}"
    @photos = {}
    @show_statuses = [ 'unavailable' ]
    @show_statuses.each do |ps|
      @photos[ps] = Photo.find( :all, :conditions => { :user_id => @current_user.id, :status => ps }, :order => 'created_at DESC', :limit => 40 )
    end
  end

  def modify_files
    if params[:status] == 'unavailable' and ( params[:new_status] == 'deleted' or params[:new_status] == 'moderation' )
      params[:photos].each do |p|
        photo = Photo.find_by_filename(p)
        if photo and photo.user_id == @current_user.id
          photo.update_status(params[:new_status])
        end
      end
    end
    redirect_to :controller => 'homepage'
  end

end
