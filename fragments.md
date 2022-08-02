```ruby
sql = <<~SQL
  WITH ranked_data AS (
    SELECT
      users.id as id,
      DENSE_RANK () OVER (ORDER BY users.id asc) user_rank
    FROM users JOIN sessions ON sessions.user_id = users.id
    WHERE sessions.date >= ? AND sessions.date <= ?
  )
  SELECT distinct id from ranked_data where user_rank <= 30;
SQL
user_ids = User.find_by_sql([sql, @start_date, @finish_date]).map(&:id)
```
