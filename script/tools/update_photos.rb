#!/usr/bin/env /usr/bin/ruby
require File.dirname(__FILE__) + "/../../config/environment"

# Simple script to iterate over the photos currently in
# the database and update their properties

photos = Photo.find(:all, :conditions => "status <> 'pending' AND status <> 'error' AND status <> 'processing'")
photos.each do |p|
  begin
    p.update_properties("private/originals/#{p.filename}")
  rescue Exception
  end
  p.save!
end
