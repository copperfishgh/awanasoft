# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
    include AuthenticatedSystem

    def all_meetings
        unless @meetings
            # This sql statement must be revised every year to only select this
            # years meetings.  
            sql = "select * from meetings where whenitbe > '2008-06-01' order by whenitbe"
            @meetings = Meeting.find_by_sql(sql)
        end
        @meetings
    end

    def all_grades
      @grades = Grade.find(:all, :order => 'display_order') unless @grades
      return @grades
    end

    def set_meeting
        if session[:meeting_id].nil?
            # find date closest to today 
            today = Date.today
            meeting_id = nil
            meetings = all_meetings
            meetings.reverse.each do |meeting|
               if today >= meeting.whenitbe
                   meeting_id = meeting.id
                   break
               end
            end
            meeting_id = meetings.first.id if meeting_id.nil?
            session[:meeting_id] = meeting_id
        end
    end

    def set_grades
        if session[:view_grades].nil?
            view_grades = {}
            Grade.find(:all).each { |g| view_grades[g.id] = true }
            session[:view_grades] = view_grades
        end
    end

    def set_numweeks
        if session[:num_weeks].nil?
            session[:num_weeks] = 1
        end
    end

    def process_query_form
        view_grades = {}
        params.each_key do |key|
            if key == 'meeting_id'
                session[:meeting_id] = params[key].to_i
            elsif key =~ /grade_id_(\d+)/
                view_grades[$1.to_i] = true
            end
        end
        # Can't allow no classes to be chosen
        session[:view_grades] = view_grades unless view_grades.size == 0
    end

end
