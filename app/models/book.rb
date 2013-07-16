class Book < ActiveRecord::Base
  has_many :clubbers
  has_many :sections
  validates_presence_of :name, :club
  validates_format_of :club,
    :with => /^(cubbies|sparks|t\&t|workers|puggles|trek)$/,
    :message => "club must be one of: 'puggles', 'cubbies', 'sparks', 't&t', 'trek', or 'workers'" 
end
