class Tag < ActiveRecord::Base
  belongs_to :photo
  belongs_to :user
  belongs_to :deleting_user, :class_name => 'User', :foreign_key => 'deleting_user_id'
  validates_presence_of :key, :value
  attr_accessible :key, :value, :area

  def self.from_json(json)
    require 'json'
    json = JSON.parse(json)
    if ! json.is_a?(Array)
      json = [ json ]
    end
    json.map do |json_tag|
      if json_tag['id']
        t = Tag.find(json_tag['id'])
        if json_tag['deleted_at'] or json_tag['deleting_user_id']
          t.deleted_at = Time.now()
        end
      else
        t = Tag.new(json_tag)
      end
      t
    end
  end

  def to_json(*a)
    hash = {
      :id => id,
      :key => key,
      :value => value,
      :mask_tag => mask_tag,
      :created_at => created_at
    }
    if area
      hash[:area] = area
    end
    if deleted_at
      hash[:deleted_at] = deleted_at
    end
    hash.to_json(*a)
  end
end
