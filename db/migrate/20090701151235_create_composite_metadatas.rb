class CreateCompositeMetadatas < ActiveRecord::Migration
  def self.up
    create_table :composite_metadatas do |t|
      t.decimal    :orientation, :tilt, :lat, :lon, :precision => 8, :scale => 5, :null => true
      t.datetime   :deleted_at, :required => false, :default => nil
      t.integer    :deleting_user_id, :required => false, :default => nil
      t.references :photo, :user, :required => true, :null => false
      t.timestamps :required => true, :null => false
    end
    add_index :composite_metadatas, [ :user_id ]
    add_index :composite_metadatas, [ :photo_id ]
  end

  def self.down
    drop_table :composite_metadatas
  end
end
