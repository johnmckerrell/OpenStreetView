class PhotoBatch < ActiveRecord::Base
  belongs_to :user
  has_many :photos
end
