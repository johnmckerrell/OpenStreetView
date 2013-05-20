class CreateLicenses < ActiveRecord::Migration
  class License < ActiveRecord::Base; end
  def self.up
    create_table :licenses do |t|
      t.string    :name, :required => true
      t.string    :url, :required => true, :length => 1000
      t.string    :description, :required => true, :length => 4000
      t.boolean   :default, :required => true, :default => false
      t.timestamps
    end
    one = License.new
    one.name = 'OSV Choice'
    one.description = 'By choosing this license you agree to use the OSV project\'s choice of license. This choice might change as new licenses are developed, by choosing this option you\'re making sure your photos are licensed under the license that we think is best for the project. Click on the link for more information about the current choice.'
    one.url = 'http://www.openstreetview.org/'
    one.default = true
    one.save

    one = License.new
    one.name = 'CC-BY'
    one.description = 'This license lets others distribute, remix, tweak, and build upon your work, even commercially, as long as they credit you for the original creation. This is the most accommodating of licenses offered, in terms of what others can do with your works licensed under Attribution'
    one.url = 'http://creativecommons.org/licenses/by/3.0'
    one.save

    one = License.new
    one.name = 'CC-BY-SA'
    one.description = 'This license lets others remix, tweak, and build upon your work even for commercial reasons, as long as they credit you and license their new creations under the identical terms. This license is often compared to open source software licenses. All new works based on yours will carry the same license, so any derivatives will also allow commercial use.'
    one.url = 'http://creativecommons.org/licenses/by-sa/3.0'
    one.save
    
    one = License.new
    one.name = 'CC-BY-NC'
    one.description = 'This license lets others remix, tweak, and build upon your work non-commercially, and although their new works must also acknowledge you and be non-commercial, they don\'t have to license their derivative works on the same terms.'
    one.url = 'http://creativecommons.org/licenses/by-nc/3.0'
    one.save

    one = License.new
    one.name = 'CC-BY-NC-SA'
    one.description = 'This license lets others remix, tweak, and build upon your work non-commercially, as long as they credit you and license their new creations under the identical terms. Others can download and redistribute your work just like the by-nc-nd license, but they can also translate, make remixes, and produce new stories based on your work. All new work based on yours will carry the same license, so any derivatives will also be non-commercial in nature.'
    one.url = 'http://creativecommons.org/licenses/by-nc-sa/3.0'
    one.save

    one = License.new
    one.name = 'CC0'
    one.description = 'Using CC0, you can waive all copyrights and related or neighboring rights that you have over your work, such as your moral rights (to the extent waivable), your publicity or privacy rights, rights you have protecting against unfair competition, and database rights and rights protecting the extraction, dissemination and reuse of data.'
    one.url = 'http://creativecommons.org/license/zero/'
    one.save

  end

  def self.down
    drop_table :licenses
  end
end
