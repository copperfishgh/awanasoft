class Visit < ActiveRecord::Base
  validates_presence_of :clubber_id, :meeting_id
  belongs_to :clubbers
  belongs_to :meetings
end
