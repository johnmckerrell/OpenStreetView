class FixPhotoDirection < ActiveRecord::Migration
  class Photo < ActiveRecord::Base; end
  def self.up
    rename_column :photos, :exif_orientation, :exif_direction
    rename_column :photos, :orientation, :direction
    add_column :photos, :orientation, :decimal, :precision => 8, :scale => 5, :null => true
    add_column :photos, :exif_orientation, :decimal, :precision => 8, :scale => 5, :null => true
    change_column :photos, :exif_orientation_source, :string, :limit => 31, :null => true
    rename_column :photos, :exif_orientation_source, :exif_direction_source
    Photo.update_all( "exif_direction_source = 'gps_img_direction'", "exif_direction_source = 'gps_img_directi'" )
    Photo.update_all( "exif_direction_source = 'gps_dest_bearing'", "exif_direction_source = 'gps_dest_bearin'" )
  end

  def self.down
    remove_column :photos, :orientation
    remove_column :photos, :exif_orientation
    rename_column :photos, :exif_direction, :exif_orientation
    rename_column :photos, :direction, :orientation
    rename_column :photos, :exif_direction_source, :exif_orientation_source
    change_column :photos, :exif_orientation_source, :string, :limit => 15, :null => true
  end
end
