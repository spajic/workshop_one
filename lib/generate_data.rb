# frozen_string_literal: true

# require 'generate_data'
# GenerateData.new(start_date: '2022-08-01', finish_date: '2022-08-30', users_num: 10000, sessions_num: 100).call
class GenerateData
  BROWSERS = [
    'Chrome',
    'Internet Explorer',
    'Firefox',
    'Mozilla',
    'Brave',
  ].freeze

  attr_reader :start_date, :finish_date, :users_num, :sessions_num

  def initialize(start_date:, finish_date:, users_num:, sessions_num:)
    @start_date = start_date
    @finish_date = finish_date
    @users_num = users_num
    @sessions_num = sessions_num
  end

  def call
    ActiveRecord::Base.transaction do
      clear_db

      (1..users_num).each do |user_num|
        user = generate_user
        generate_sessions_for_user(user)
        puts "Finish generating data for user #{user_num}"
      end
    end
  end

  private

  def clear_db
    User.delete_all
    Session.delete_all
  end

  def generate_user
    User.create(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      age: 18 + Random.rand(50),
      email: Faker::Internet.free_email,
    )
  end

  def generate_sessions_for_user(user)
    (1 + Random.rand(sessions_num)).times do
      session = Session.create(
        browser: "#{BROWSERS.sample} v#{Random.rand(50) + 1}",
        duration: Random.rand(60) + 1,
        date: possible_dates.sample,
        country: Faker::Address.country
      )
      user.sessions << session
    end
  end

  def possible_dates
    @possible_dates ||= (Date.parse(start_date)..Date.parse(finish_date)).to_a
  end
end
