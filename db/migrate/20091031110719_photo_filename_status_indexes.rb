class PhotoFilenameStatusIndexes < ActiveRecord::Migration
  def self.up
    add_index :photos, [ :status ], :name => :photos_status
    add_index :photos, [ :filename ], :name => :photos_filename
  end

  def self.down
    remove_index :photos, :name => :photos_status
    remove_index :photos, :name => :photos_filename
  end
end
