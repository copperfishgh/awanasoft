class WeeklyController < ApplicationController
  before_filter :login_required, :set_meeting, :set_grades
  layout('awana')

  def mark_clubber
    meeting_id = session[:meeting_id]
    clubber_id = params[:id]
    sql = "SELECT c.*, v.meeting_id, v.prepared, v.id as visit_id FROM clubbers c LEFT JOIN visits v ON v.clubber_id = c.id AND v.meeting_id = #{session[:meeting_id]}
            WHERE c.id = #{clubber_id}"
    clubber = Clubber.find_by_sql(sql).first
    if clubber.visit_id
      Visit.delete(clubber.visit_id)
    else
      Visit.create(:clubber_id => clubber.id, :meeting_id => meeting_id, :prepared => 1).save!
    end
    clubber = Clubber.find_by_sql(sql).first
    # now toggle and update state
    render(:partial => 'clubber', :locals => { :clubber => clubber })
  end
  
  def clubber_prepared
    meeting_id = session[:meeting_id]
    clubber_id = params[:id]
    visit = Visit.find_by_clubber_id_and_meeting_id(clubber_id, meeting_id)
    visit.prepared = visit.prepared.nil? ? 1 : nil
    visit.save!
    sql = "SELECT c.*, v.meeting_id, v.prepared, v.id as visit_id FROM clubbers c INNER JOIN visits v ON v.clubber_id = c.id AND v.meeting_id = #{session[:meeting_id]}
            WHERE c.id = #{clubber_id}"
    clubber = Clubber.find_by_sql(sql).first
    require 'yaml'
    # now toggle and update state
    render(:partial => 'clubber', :locals => { :clubber => clubber })
  end
  
  def mark_section
    section_id = params[:id]
    clubber_id = session[:clubber_id]
    complete = Complete.find_by_clubber_id_and_section_id(clubber_id, section_id)
    if complete
      complete.destroy
      complete = nil
    else
      complete = Complete.create(:clubber_id => clubber_id,
                      :section_id => section_id,
                      :meeting_id => session[:meeting_id])
      complete.save!
    end
    locals = { :complete => complete, :section => Section.find(section_id)  }
    render(:partial => 'section', :locals => locals)
  end

  def change_book
    book_id = params[:id]
    clubber_id = session[:clubber_id]
    clubber = Clubber.find(clubber_id)
    clubber.book_id = book_id
    clubber.save
    locals = { 
      :clubber => clubber,
      :books => clubber.club == 'workers' ? Book.find(:all, :conditions=>'active=1') : Book.find_all_by_club(clubber.club, :order => 'display_order', :conditions=>'active=1'),
      :meeting_id => session[:meeting_id],
      :completed => Complete.find_all_by_clubber_id(clubber_id),
      :sections => Section.find_all_by_book_id(clubber.book_id, :order => "optional, display_order")
    }
    render :partial => 'sections', :locals => locals
  end
   
  def sections
    clubber_id = params[:id]
    session[:clubber_id] = clubber_id
    clubber = Clubber.find(clubber_id)
    if clubber.book.club != clubber.club && clubber.club != 'workers'
      clubber.book_id = Book.find_by_club(clubber.club).id
      clubber.save
    end
    locals = { 
      :clubber => clubber,
      :books => clubber.club == 'workers' ? Book.find(:all, :conditions=>'active=1') : Book.find_all_by_club(clubber.club, :order => 'display_order', :conditions=>'active=1'),
      :meeting_id => session[:meeting_id],
      :completed => Complete.find_all_by_clubber_id(clubber_id),
      :sections => Section.find_all_by_book_id(clubber.book_id, :order => "optional, display_order")
    }
    render :partial => 'sections', :locals => locals
  end  

  def change_view
      process_query_form
      redirect_to :back
  end
  
  def index
    session[:edit_came_from] = { :controller => 'weekly', :action => 'index' }

    # prepare variables required by form
    @all_meetings = all_meetings()
    @all_grades = all_grades()
    @selected_meeting = Meeting.find(session[:meeting_id])
    @selected_grades = session[:view_grades]

    sql = "SELECT c.*, v.meeting_id, v.prepared FROM clubbers c LEFT JOIN visits v ON v.clubber_id = c.id AND v.meeting_id = #{session[:meeting_id]}
            WHERE c.active = TRUE
            AND c.grade_id IN (#{session[:view_grades].keys.join(", ")})
            ORDER BY c.last, c.first"
    @clubbers = Clubber.find_by_sql(sql)
  end
end
