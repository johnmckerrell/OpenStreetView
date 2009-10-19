#!/usr/bin/env /usr/bin/ruby
require File.dirname(__FILE__) + "/../../config/environment"

# Simple script to iterate over the photos currently in
# the database and update their properties

photos = Photo.find(:all, :conditions => "created_at >= '2009-09-30 20:55:16' AND status = 'deleted'")

photos.each do |p|
  begin
    p.update_safeness
  rescue Exception
  end
  p.save!
end
