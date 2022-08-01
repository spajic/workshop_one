# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :sessions

  validates :email, email: { mx_with_fallback: true }
end
