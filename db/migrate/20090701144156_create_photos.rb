class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      t.decimal   :exif_orientation, :exif_tilt, :exif_lat, :exif_lon, :orientation, :tilt, :lat, :lon, :precision => 8, :scale => 5, :null => true
      t.column    :status, :string, :null => false, :default => 'processing'
      t.datetime  :taken_at, :exif_taken_at
      t.integer   :approval_count, :null => false, :default => 0
      t.integer   :approval_needed, :null => false, :default => 9999
      t.string    :exif_orientation_source, :limit => 15, :null => true
      t.string    :source_url, :limit => 1000, :null => true
      t.string    :filename, :limit => 40, :null => false
      t.references :user, :photo_batch, :license
      t.timestamps
    end
    add_index :photos, [ :user_id ]
    add_index :photos, [ :photo_batch_id ]
  end

  def self.down
    drop_table :photos
  end
end
