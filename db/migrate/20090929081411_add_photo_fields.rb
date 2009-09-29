class AddPhotoFields < ActiveRecord::Migration
  def self.up
    add_column :photos, :filesize, :int, :null => true
    add_column :photos, :original_width, :int, :null => true
    add_column :photos, :original_height, :int, :null => true
  end

  def self.down
    remove_column :photos, :filesize
    remove_column :photos, :original_width
    remove_column :photos, :original_height
  end
end
