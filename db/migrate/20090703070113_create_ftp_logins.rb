class CreateFtpLogins < ActiveRecord::Migration
  def self.up
    create_table :ftp_logins do |t|
      t.string :username, :password, :path, :required => true, :null => false
      t.references :user, :required => true, :null => false
      t.timestamps :required => true, :null => false
    end
  end

  def self.down
    drop_table :ftp_logins
  end
end
