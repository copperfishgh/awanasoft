class Grade < ActiveRecord::Base
  has_many :clubbers
  validates_presence_of :name, :club
  validates_format_of :club,
    :with => /^(cubbies|sparks|t\&t|workers|puggles|trek)$/,
    :message => "club must be one of: 'cubbies', 'sparks', 't&t', 'puggles', 'trek', or 'workers'" 
end
