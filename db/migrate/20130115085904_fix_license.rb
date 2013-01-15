class FixLicense < ActiveRecord::Migration
  class License < ActiveRecord::Base; end
  def self.up
    l = License.find_by_name('OSV Choice')
    l.description = 'By choosing this license you agree to use the OSV project\'s choice of license. This choice might change as new licenses are developed, by choosing this option you\'re making sure your photos are licensed under the license we think is best for the project'
    l.save
  end

  def self.down
    l = License.find_by_name('OSV Choice')
    l.description = 'By choosing this license you agree to use the OSV project\'s choice of license. This choice might change as new licenses are developed, by choosing this option you\'re making sure your photos are licensed under the license that we think is best for the project. Click on the link for more information about the current choice.'
    l.save
  end
end
