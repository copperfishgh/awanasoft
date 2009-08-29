class Complete < ActiveRecord::Base
  validates_presence_of :clubber_id, :section_id, :meeting_id
  belongs_to :clubber
  belongs_to :section
  belongs_to :meeting
end
