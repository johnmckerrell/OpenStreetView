class CompositeMetadata < ActiveRecord::Base
  belongs_to :photo
  belongs_to :user
  belongs_to :deleting_user, :class_name => 'User', :foreign_key => 'deleting_user_id'
  attr_accessible :orientation, :tilt, :lat, :lon

  def to_json(*a)
    hash = {
      :id => id,
      :created_at => null
    }
    if orientation
      hash[:orientation] = orientation
    end
    if tilt
      hash[:tilt] = tilt
    end
    if lat and lon
      hash[:lat] = lat
      hash[:lon] = lon
    end
    if deleted_at
      hash[:deleted_at] = deleted_at
    end
  end

  protected
  def validate
    if orientation.nil? and tilt.nil? and ( lat.nil? or lon.nil?)
      errors.add_to_base("You must specify at least one of orientation, tilt or lat and lon")
    end
  end
end
