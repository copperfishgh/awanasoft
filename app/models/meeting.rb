Months = %w{Skip Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
class Meeting < ActiveRecord::Base
  has_many :visits, :dependent => :destroy
  has_many :clubbers, :through => :visits
  validates_presence_of :whenitbe
  
  def nice
    t = self.whenitbe
    "#{Months[t.mon]} #{t.day}, #{t.year}"
  end
end
