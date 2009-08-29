class FixmeupController < ApplicationController
  layout('awana')

  def fix_notes
      sql = "SELECT * FROM clubbers c"
      @records = Clubber.find_by_sql(sql)
      @records.each do |r|
        r.notes = r.notes.split("\n").collect {|line| line.strip}.join("\n").gsub(/[\]\[]/,'')
        r.save
      end
      render :text => '<html><body>Notes fixed.</body></html>'
  end
end
