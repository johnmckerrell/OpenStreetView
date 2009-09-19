class CreateUnsafeFlags < ActiveRecord::Migration
  def self.up
    create_table :unsafe_flags do |t|
      t.boolean    :active, :null => false, :required => true, :default => true
      t.references :user, :photo, :null => false, :required => true
      t.timestamps :required => true, :null => false
      t.string     :notes, :null => false, :default => ''
    end
    add_index :unsafe_flags, [ :user_id ]
    add_index :unsafe_flags, [ :photo_id ]
  end

  def self.down
    drop_table :unsafe_flags
  end
end
