class Clubber < ActiveRecord::Base
  has_one :book
  has_one :grade
  has_many :visits, :dependent => :destroy
  has_many :completes, :dependent => :destroy
  has_many :meetings, :through => :visits
  has_many :sections, :through => :completes
  validates_presence_of :first, :last, :gender, :grade_id
  validates_format_of :gender,
    :with => /^[MF]$/,
    :message => "must either M or F" 
  
  def grade
    Grade.find(attributes['grade_id'])
  end
  
  def classname
    grade.name
  end
  
  def book
    Book.find(attributes['book_id'])
  end
  
  def club
    self.grade.club
  end

end
