class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string      :key, :value, :null => false, :required => true, :default => ''
      t.string      :area, :required => false, :default => nil
      t.datetime    :deleted_at, :required => false, :default => nil
      t.integer     :deleting_user_id, :required => false, :default => nil
      t.boolean     :mask_tag, :null => false, :required => true, :default => false
      t.references  :user, :photo, :null => false, :required => true
      t.timestamps  :null => false, :required => true
    end
    add_index :tags, [ :photo_id ]
    add_index :tags, [ :user_id ]
  end

  def self.down
    drop_table :tags
  end
end
