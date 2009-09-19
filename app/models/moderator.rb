class Moderator < ActiveRecord::Base
  belongs_to :user
  belongs_to :photo

  def to_json(*p)
    {
      'created_at'  => created_at,
      'updated_at'  => updated_at,
      'status'      => status
    }.to_json(*p)
      #'photo' => photo
  end

end
