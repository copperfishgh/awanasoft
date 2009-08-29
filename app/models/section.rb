class Section < ActiveRecord::Base
  has_many :completes, :dependent => :destroy
  has_many :clubbers, :through => :completes
  belongs_to :book
end
