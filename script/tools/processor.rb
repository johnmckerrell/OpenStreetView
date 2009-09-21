#!/usr/bin/env /usr/bin/ruby
require File.dirname(__FILE__) + "/../../config/environment"

while true do

  ActiveRecord::Base.connection.execute("LOCK TABLES photos WRITE")
  p = Photo.find(:first, :conditions => { :status => 'pending' } )
  if p
    p.status = 'processing'
    p.save
  end
  ActiveRecord::Base.connection.execute("UNLOCK TABLES")
  if p
    p.process
    puts "Sleeping for 5 seconds"
    sleep 5
  else
    puts "Sleeping for a minute"
    sleep 60
  end
end
