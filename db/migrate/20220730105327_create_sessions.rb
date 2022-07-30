class CreateSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :sessions do |t|
      t.belongs_to :user
      t.string :browser
      t.integer :duration
      t.date :date
      t.string :country

      t.timestamps
    end
  end
end
