# frozen_string_literal: true

class Loop
  FINISH_DATE_FOR_METRIC_CALCULATION = '2022-08-01'
  REPEATS = 3
  THRESHOLD_METRIC = 4 # seconds
  APPROX_BUDGET = 0.15 # seconds

  def call
    check_correctness
    current_metric = calculate_metric
    protect_from_regress(current_metric)
    # check_approx_budget(current_metric)
    # check_final_budget
  end

  private

  # update etalon with
  # http 'localhost:3000/reports?start_date=2022-08-01&finish_date=2022-08-02' > tmp/etalon.html
  def check_correctness
    result = get(finish_date)
    etalon = File.read('tmp/etalon.html')
    if result == etalon
      puts '✅ Correctness test passed'
    else
      raise '❌❌❌ CORRECTNESS TEST FAILED'
    end
  end

  def get(finish_date)
    uri = URI("http://localhost:3000/reports?start_date=2022-08-01&finish_date=#{finish_date}")
    Net::HTTP.ger_response(uri)
  end

  def calculate_metric
    total_time = 0
    REPEATS.times do
      start = Time.now
      get(FINISH_DATE_FOR_METRIC_CALCULATION)
      total_time += Time.now - start
    end
    total_time / REPEATS
  end

  def protect_from_regress(current_metric)
    if current_metric < THRESHOLD_METRIC
      puts "✅ Protect from performance regression test passed: #{current_metric} < #{THRESHOLD_METRIC}"
    else
      raise "❌❌❌ PERFORMANCE GOT WORSE: #{current_metric} > #{THRESHOLD_METRIC}"
    end
  end
end
