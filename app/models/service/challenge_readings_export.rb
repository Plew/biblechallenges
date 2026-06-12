require 'csv'

class ChallengeReadingsExport
  def initialize(challenge)
    @challenge = challenge
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      # Define the headers you want in your spreadsheet
      csv << ["Group Name", "User Name", "Email", "Chapter", "Assigned Reading Date", "Date Logged", "On Schedule?"]

      # Eager load relationships to prevent N+1 database query issues
      memberships = @challenge.memberships.includes(:user, :group, membership_readings: [:reading, :chapter])

      memberships.find_each do |membership|
        group_name = membership.group ? membership.group.name : "Unassigned"
        user_name  = membership.user ? membership.user.name : "Unknown"
        email      = membership.user ? membership.user.email : "Unknown"

        membership.membership_readings.each do |mr|
          # Fallback check depending on how the chapter relationship is mapped
          chapter_name = if mr.chapter
                           mr.chapter.book_and_chapter
                         elsif mr.reading && mr.reading.chapter
                           mr.reading.chapter.book_and_chapter
                         else
                           "N/A"
                         end
          
          assigned_date = mr.reading ? mr.reading.read_on : "N/A"
          logged_at     = mr.created_at ? mr.created_at.to_date : "N/A"
          on_schedule   = mr.on_schedule ? "Yes" : "No"

          csv << [group_name, user_name, email, chapter_name, assigned_date, logged_at, on_schedule]
        end
      end
    end
  end
end