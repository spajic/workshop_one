```ruby
sql = <<~SQL
  WITH ranked_data AS (
    SELECT
      users.*,
      DENSE_RANK () OVER (ORDER BY users.id asc) user_rank
    FROM users JOIN sessions ON sessions.user_id = users.id
    WHERE sessions.date >= ? AND sessions.date <= ?
  )
  SELECT distinct * from ranked_data where user_rank <= 500 ORDER BY id;
SQL

users = User.find_by_sql([sql, @start_date, @finish_date])
sessions_array = Session.where(user: users).where('date >= :start_date AND date <= :finish_date', start_date: @start_date, finish_date: @finish_date).to_a
```
