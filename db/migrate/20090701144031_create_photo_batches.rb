class CreatePhotoBatches < ActiveRecord::Migration
  def self.up
    create_table :photo_batches do |t|
      t.references  :user
      t.string      :name
      t.timestamps
    end
    add_index :photo_batches, [ :user_id ]
  end

  def self.down
    drop_table :photo_batches
  end
end
