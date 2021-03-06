class User < ApplicationRecord
  before_save :downcase_login
  after_create :add_user_group

  def downcase_login
    self.login = self.login.downcase
  end

  def email
    self.login + "@lanzatech.com"
  end

  def get_name
    self.login.sub('.', ' ').split.map(&:capitalize).join(' ')
  end

  def get_name_link
    self.login.sub('.', '')
  end

  def add_user_group
    UserGroups.delay.some([self.login])
  end

  # Gets various metrics for user_show.
  def self.get_show_metrics(user, min_date, max_date, is_manager)

    requests = Request.where("updated_at >= ? AND updated_at <= ?", min_date, max_date)

    # Blank objects in case user isn't manager.
    non_manager_metrics = ActiveSupport::OrderedHash.new
    analysis = []

    if is_manager
      analysis = User.manager_analytics(min_date, max_date)
      non_manager_metrics["Total"] = []
      non_manager_metrics["Department"] = []
      non_manager_metrics["Total"] = User.user_analytics(requests)
      non_manager_metrics["Department"] = User.requests_by_group(requests)

      non_managers = User.where("admin = ? AND login != ? AND director = ?", true, user.login, false)
      non_managers.each do |non_manager|
        user_requests = requests.where("name = ? OR customer = ? OR assignment like ?", non_manager.login, non_manager.login, "%#{non_manager.login}%")
        non_manager_metrics[non_manager] = User.user_analytics(user_requests)
      end
    end

    user_requests = requests.where("name = ? OR customer = ? OR assignment like ?", user.login, user.login, "%#{user.login}%")
    user_metrics = User.user_analytics(user_requests)

    return non_manager_metrics, user_metrics, analysis
  end

  # Given two dates, return a number of results.
  def self.manager_analytics (min, max)
    analytics_list = {}

    if min != "" and max != ""
      min = min.to_datetime
      max = max.to_datetime

      # Before.
      before = Request.where("created_at <= ?", min)
      analytics_list["before_pending"] = before.where("status = ?", "Pending")
      analytics_list["before_ongoing"] = before.where("status = ?", "Ongoing")
      analytics_list["before_completed_in_period"] = before.where("updated_at >= ? AND updated_at <= ? AND status = ?", min, max, "Complete")

      # During.
      during = Request.where("created_at >= ? AND created_at <= ?", min, max)
      analytics_list["during_pending"] = during.where("status = ?", "Pending")
      analytics_list["during_ongoing"] = during.where("status = ?", "Ongoing")
      analytics_list["during_completed"] = during.where("status = ?", "Complete")

      # Totals.
      analytics_list["ongoing_pending"] = analytics_list["before_pending"].count + analytics_list["before_ongoing"].count + analytics_list["during_pending"].count + analytics_list["during_ongoing"].count
      analytics_list["completed"] = analytics_list["before_completed_in_period"].count + analytics_list["during_completed"].count
    end

    return analytics_list
  end

  # Returns requests launched and completed as well as data for per stage
  # and per request times over a set of requests.
  def self.user_analytics(requests)
    analytics_list = {}
    analytics_list["requests"] = requests
    analytics_list["requests_launched"] = analytics_list["requests"].length
    requests_completed = analytics_list["requests"].select { |x| x.status == "Complete" }
    analytics_list["requests_completed"] = requests_completed.length
    time_spent_per_request = []

    time_spent_per_stage = []

    requests_completed.each do |r|
      time_spent_per_request << [r.title, r.tothours, r.esthours]
      time_spent_per_stage << self.determine_pending_and_ongoing_times(r)
    end

    analytics_list["time_spent_per_request"] = time_spent_per_request
    analytics_list["time_spent_per_stage"] = time_spent_per_stage

    return analytics_list
  end

  # Determines the pending and ongoing times of a request.
  def self.determine_pending_and_ongoing_times(r)
    res = []
    res << r.title
    stathist = r.stathist
    pending = r.created_at.to_date

    begin
      ongoing = Date.parse stathist.match(/Ongoing:\s(\d+-\d+-\d+)/)[-1]
      res << (pending..ongoing).count

      complete = Date.parse stathist.match(/Complete:\s(\d+-\d+-\d+)/)[-1]
      res << (ongoing..complete).count
    rescue NoMethodError => exception
      res << 0
      res << 0
    end

    return res
  end

  # Creates a departmental breakdown of requests.
  def self.requests_by_group(requests)

    analytics_list = ActiveSupport::OrderedHash.new

    analytics_list["Synthetic Biology"] = 0
    analytics_list["Engineering"] = 0
    analytics_list["Process Engineering"] = 0
    analytics_list["Fermentation"] = 0
    analytics_list["Bioinformatics"] = 0
    analytics_list["Process Validation"] = 0
    analytics_list["CSO"] = 0
    customer_requests = requests.select { |x| x.customer.present? }
    analytics_list["Bioinformatics"] = requests.length - customer_requests.length
    customer_requests.each do |r|
      customer = User.where("login = ?", r.customer).first
      if customer.group
        analytics_list[User.where("login = ?", r.customer).first.group] += 1
      end
    end
    analytics_list.to_a
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :rememberable, :trackable
end
