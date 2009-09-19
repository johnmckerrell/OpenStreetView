class CreateModerators < ActiveRecord::Migration
  def self.up
    create_table :moderators do |t|
      t.references :user, :photo, :null => false, :required => true
      t.string     :status, :default => 'pending', :required => true, :null => false
      t.timestamps :required => true, :null => false
    end
    add_index :moderators, [ :user_id, :status ]
    add_index :moderators, [ :photo_id, :status ]
    add_index :moderators, [ :user_id, :photo_id ]
  end

  def self.down
    drop_table :moderators
  end
end
