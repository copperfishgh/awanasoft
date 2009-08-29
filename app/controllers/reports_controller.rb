class ReportsController < ApplicationController
  before_filter :login_required
  layout('awana')

  def index
    session[:filter_came_from] = { :controller => 'reports' }
    @meeting = Meeting.find(session[:meeting_id])
  end

#################################################################################

  def awards_form
      init_form_class_variables
  end

  def awards_report
      sql = "SELECT g.club, g.name as 'class', c.last, c.first, s.award
            FROM grades g INNER JOIN clubbers c ON c.grade_id = g.id
            INNER JOIN completes l ON l.clubber_id = c.id
            INNER JOIN sections s ON l.section_id = s.id 
            #{form_clause}
            AND 
             c.active = 1 AND
	s.award IS NOT NULL"
            
      @records = Clubber.find_by_sql(sql)
      @title = %w{club class last first award}
      render :action => 'records'
  end

#################################################################################

  def attendance_form
      init_form_class_variables
  end

  def attendance_report
      low_meeting_id = params['low_meeting_id']
      high_meeting_id = params['high_meeting_id']
      low_meeting = Meeting.find(low_meeting_id)
      high_meeting = Meeting.find(high_meeting_id)

      # find all meetings
      meetings = Clubber.find_by_sql("
        SELECT * FROM meetings m 
	WHERE m.whenitbe >= '#{low_meeting.whenitbe}'
	AND m.whenitbe <= '#{high_meeting.whenitbe}'")

      # find all clubbers
      clubbers = Clubber.find_by_sql("
            SELECT g.club, g.name, c.last, c.first, c.id, '' as 'attendance', 0 as 'present', 0 as 'absent'
            FROM grades g INNER JOIN clubbers c ON c.grade_id = g.id
            #{form_clause}")

      # mark all clubbers absent until proven present!
      visit_hash = {}
      clubbers.each do |clubber|
	  visit_hash[clubber.id] = Array.new(meetings.size, 0)
      end
      i = 0
      meetings.each do |meeting|
	      visits = Clubber.find_by_sql("
		    SELECT v.clubber_id 
		    FROM visits v
		    WHERE v.meeting_id = #{meeting.id}
		    ")
	      visits.each do |visit|
      		cid = visit.clubber_id.to_i
	      	if visit_hash.member?(cid)
	          visit_hash[cid][i] = 1
		end
	      end
	      i += 1
      end

      # now populate attendance, number of times present and absent
      clubbers.each do |clubber|
      	  clubber.present = 0
	  a = visit_hash[clubber.id]
	  a.each do |v| 
	  	clubber.present += v
		clubber.attendance += (v == 1) ? '*' : '-'
	  end
	  clubber.absent = meetings.size - clubber.present
      end

      @title = %w{club name last first attendance present absent}

      @records = clubbers
      render :action => 'records'
  end

  def points_form
      init_form_class_variables
  end

  def points_report
      low_meeting_id = params['low_meeting_id']
      high_meeting_id = params['high_meeting_id']
      low_meeting = Meeting.find(low_meeting_id)
      high_meeting = Meeting.find(high_meeting_id)
      @selected_grades = session[:view_grades]
      c = ActiveRecord::Base.connection()
      c.execute "DROP TEMPORARY TABLE IF EXISTS points_report"
      c.execute "CREATE TEMPORARY TABLE points_report
            ( club char(100), name char(100), last char(100), first char(100), points int);"
      c.execute "INSERT INTO points_report
            SELECT g.club, g.name, c.last, c.first, 0 as 'points'
            FROM grades g INNER JOIN clubbers c ON c.grade_id = g.id
            #{form_clause}
           " 
      c.execute "INSERT INTO points_report
            SELECT g.club, g.name, c.last, c.first, count(*) as 'points'
            FROM grades g INNER JOIN clubbers c ON c.grade_id = g.id
            INNER JOIN completes l ON l.clubber_id = c.id
            INNER JOIN meetings m on l.meeting_id = m.id
            #{form_clause}
            AND m.whenitbe >= '#{low_meeting.whenitbe}'
            AND m.whenitbe <= '#{high_meeting.whenitbe}'
            GROUP BY g.club, g.name, c.last, c.first
           " 
      c.execute "INSERT INTO points_report
            SELECT g.club, g.name, c.last, c.first, count(*) as 'points'
            FROM grades g INNER JOIN clubbers c ON c.grade_id = g.id
            INNER JOIN visits v ON v.clubber_id = c.id
            INNER JOIN meetings m on v.meeting_id = m.id
            #{form_clause}
            AND m.whenitbe >= '#{low_meeting.whenitbe}'
            AND m.whenitbe <= '#{high_meeting.whenitbe}'
            AND v.prepared IS NOT NULL
            GROUP BY g.club, g.name, c.last, c.first
           " 
      @records = Clubber.find_by_sql("
            SELECT p.club, p.name as 'class', p.last, p.first, sum(points) as 'points' FROM points_report p
            GROUP BY club, name, last, first
            ORDER BY club, name, last, first")
      @title = %w{club class last first points}
      render :action => 'records'
  end

#################################################################################
 
  def pickup_form
      init_form_class_variables
  end

  def pickup_report
      sql = "SELECT g.name as 'classname', c.last, c.first, c.notes 
            FROM grades g INNER JOIN clubbers c ON c.grade_id = g.id
            #{form_clause}
            ORDER by g.name, c.last, c.first"
      @records = Clubber.find_by_sql(sql)
      @records.each do |r|
          s = parents(r.notes)
          if r.notes =~ /^pickup:(.*)$/i
              s += "<br/>Pickup notes:  #{$1}"
          end
          r['pickup'] = s
      end
      @title = %w{classname last first pickup}
      render :action => 'records'
  end

#################################################################################

  def birthday_form
      init_form_class_variables
  end

  def birthday_report
      sql = "SELECT  c.last, c.first, 
      monthname(c.birthday) as 'month',
      dayofmonth(c.birthday) as 'day', year(c.birthday) as 'year' 
            FROM grades g INNER JOIN clubbers c ON c.grade_id = g.id
            #{form_clause}
            ORDER by  month(c.birthday), dayofmonth(c.birthday), year(c.birthday), c.last, c.first"
      @records = Clubber.find_by_sql(sql)
      @title = %w{month day year last first}
      render :action => 'records'
  end

#################################################################################

  def van_form
      init_form_class_variables
  end

  def van_report
      sql = "SELECT g.name as 'classname', c.last, c.first, c.notes 
            FROM grades g INNER JOIN clubbers c ON c.grade_id = g.id
            #{form_clause}
            ORDER by g.name, c.last, c.first"
      @records = Clubber.find_by_sql(sql).select do |r|
            r.notes =~ /van:/i
      end
      @title = %w{classname last first}
      render :action => 'records'
  end

#################################################################################

  def absent_form
      init_form_class_variables
  end

  def absent_report
      view_grades = []
      params.each_key do |key|
          if key =~ /grade_id_(\d+)/
              view_grades << $1
          end
      end
      # Can't allow no classes to be chosen
      grade_clause = ''
      if view_grades.size > 0
          grade_clause = " AND grade_id in (#{view_grades.join(', ')})"
      end

      sql = "SELECT c.first, c.last, c.address, c.city, c.state, c.zip
             FROM clubbers c 
             LEFT JOIN visits v 
             ON v.clubber_id = c.id AND v.meeting_id = #{params['meeting_id']}
             WHERE 
             c.active = 1 AND
             v.meeting_id IS NULL
             #{grade_clause}
             ORDER by c.last, c.first"
      @records = Clubber.find_by_sql(sql)

      if params['combine_address']
          keep = []
          last_address = ''
          @records.each do |r|
              if r.address == last_address && r.address.strip != ''
                  markup = keep.last
                  unless markup.last == 'Family'
                      markup.first = markup.last
                      markup.last = 'Family'
                  end
                  next
              end
              keep << r
              last_address = r.address
          end
          @records = keep 
      end
      @title = %w{first last address city state zip}
      report = [@title.join(', ')]
      @records.each do |r|
          a = []
          @title.each do |t|
            a << r[t]
          end
          report << a.join(', ')
      end
      send_data report.join("\n"), :filename => 'absentee_list.csv'
      #render :action => 'records'
  end

#################################################################################

  def contact_form
      init_form_class_variables
  end

  def contact_report
      sql = "SELECT c.first, c.last, c.address, c.city, c.state, c.zip, c.birthday, c.active, c.notes
            FROM clubbers c
            #{form_clause}
            ORDER by c.last, c.first"
      @records = Clubber.find_by_sql(sql)

      @title = %w{first last address city state zip parents phone}
      report = [@title.join(', ')]
      @records.each do |r|
          a = []
          @title.each do |t|
              if t == 'parents'
                  a << parents(r.notes)
              elsif t == 'phone'
                  a << phone(r.notes)
              else
                  a << r[t]
              end
          end
          report << a.join(', ')
      end
      send_data report.join("\n"), :filename => 'mailing_list.csv'
  end

#################################################################################

  def mailer_form
      init_form_class_variables
  end

  def mailer_report
      sql = "SELECT c.first, c.last, c.address, c.city, c.state, c.zip
            FROM clubbers c
            #{form_clause}
            AND  c.active = 1
            ORDER by c.last, c.first"
      @records = Clubber.find_by_sql(sql)

      if params['combine_address']
          keep = []
          last_address = ''
          @records.each do |r|
              if r.address == last_address && r.address.strip != ''
                  markup = keep.last
                  unless markup.last == 'Family'
                      markup.first = markup.last
                      markup.last = 'Family'
                  end
                  next
              end
              keep << r
              last_address = r.address
          end
          @records = keep 
      end
      @title = %w{first last address city state zip}
      report = [@title.join(', ')]
      @records.each do |r|
          a = []
          @title.each do |t|
            a << r[t]
          end
          report << a.join(', ')
      end
      send_data report.join("\n"), :filename => 'mailing_list.csv'
  end

#################################################################################

  private
    def init_form_class_variables
        # prepare variables required by form
        @all_meetings = all_meetings()
        @all_grades = all_grades()
        @selected_meeting = Meeting.find(session[:meeting_id])
        @selected_grades = session[:view_grades]
    end

    def form_clause
        clauses = []
        view_grades = {}
        params.each_key do |key|
            if key == 'meeting_id'
                clauses << " meeting_id = #{params[key]}"
            elsif key =~ /grade_id_(\d+)/
                view_grades[$1.to_i] = true
            end
        end
        # Can't allow no classes to be chosen
        if view_grades.size > 0
            clauses << "grade_id in (#{view_grades.keys.join(', ')})"
        end
        return clauses.size == 0 ? "" : "WHERE #{clauses.join(' AND ')}"
    end

    def parents(s)
        m = ''
        d = ''
        if s =~ /^mom:(.*)$/i
            m = $1.strip
        end
        if s =~ /^dad:(.*)$/i
            d = $1.strip
        end
        if m.size > 0 and d.size > 0
            return "Parents:  #{m} & #{d}"
        elsif m.size > 0
            return "Mom: #{m}"
        elsif d.size > 0
            return "Dad: #{d}"
        else
            return ""
        end
    end

    def phone(s)
        p = []
        s.each do |line|
            p << line.strip if line=~/phone/i 
        end
        return p.size > 0 ? p.join('    ') : ''
    end

end
