# frozen_string_literal: true

class ReportsController < ApplicationController
  around_action :profile, only: :index

  def profile(&block)
    if params[:profile] == 'stackprof'
      profile = StackProf.run(mode: :wall, raw: true, &block)
      File.write('tmp/stackprof.json', JSON.generate(profile))
    elsif params[:profile] == 'rubyprof'
      RubyProf.measure_mode = RubyProf::WALL_TIME
      RubyProf.start
      yield
      results = RubyProf.stop

      File.open("tmp/rubyprof.json", 'w') do |f|
        RubyProf::SpeedscopePrinter.new(results).print(f)
      end
    elsif params[:profile] == 'allocations'
      RubyProf.measure_mode = RubyProf::ALLOCATIONS
      RubyProf.start
      yield
      results = RubyProf.stop

      printer = RubyProf::CallTreePrinter.new(results)
      printer.print(path: 'tmp')
    elsif params[:profile] == 'memory'
      RubyProf.measure_mode = RubyProf::MEMORY
      RubyProf.start
      yield
      results = RubyProf.stop

      printer = RubyProf::CallTreePrinter.new(results)
      printer.print(path: 'tmp')
    else
      yield
    end
  end

  def index
    @start_date = Date.parse params.require(:start_date)
    @finish_date = Date.parse params.require(:finish_date)

    sessions = Session.where(
      'date >= :start_date and date <= :finish_date', # тянуть все и фильтровать в Ruby?
      start_date: @start_date,
      finish_date: @finish_date,
    ).order(:user_id)


    users =
      User
        .where(id: sessions.pluck(:user_id))
        .order(:id)
        .limit(30)

    sessions = sessions.where(user_id: users.pluck(:id))

    @total_users = users.count
    @total_sessions = sessions.count

    users_array = users.to_a
    users_array = select_valid_users(users)
    sessions_array = sessions.to_a

    @unique_browsers_count = unique_browsers_count(sessions_array)

    @users = []
    users_array.each do |user|
      user_sessions = select_sessions_of_user(user, sessions_array)
      @users = @users + [stats_for_user(user, user_sessions)]
    end
  end

  private

  def select_valid_users(users)
    users.select(&:valid?)
  end

  def unique_browsers_count(sessions)
    sessions.map(&:browser).map(&:upcase).uniq.count
  end

  def select_sessions_of_user(user, sessions_array)
    sessions_array.select {|session| session.user_id == user.id}
  end

  def stats_for_user(user, user_sessions)
    {
      first_name: user.first_name,
      last_name: user.last_name,
      sessions_count: user_sessions.count,
      total_time: "#{user_sessions.map(&:duration).sum} min.",
      longest_session: "#{user_sessions.map(&:duration).max} min.",
      browsers: user_sessions.map(&:browser).map(&:upcase).sort.uniq,
      used_ie: user_sessions.map(&:browser).map(&:upcase).any? {|browser| browser =~ /INTERNET EXPLORER/},
      used_only_chrome: user_sessions.map(&:browser).map(&:upcase).all? {|browser| browser =~ /CHROME/ },
      dates: user_sessions.map(&:date).map(&:to_s).sort.uniq
    }
  end
end
