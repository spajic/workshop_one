# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'pry-byebug'

class Loop
  FINISH_DATE_FOR_ETALON = '02-08-2022'
  FINISH_DATE_FOR_METRIC_CALCULATION = '01-08-2022'
  FINAL_FINISH_DATE = '30-08-2022'
  REPEATS = 3
  THRESHOLD_METRIC = 4 # seconds
  APPROX_BUDGET = 0.15 # seconds
  FINAL_BUDGET = 5 # seconds

  def call
    check_correctness
    current_metric = calculate_metric
    protect_from_regress(current_metric)
    check_approx_budget(current_metric)
    check_final_budget
  end

  private

  # update etalon with
  # http 'localhost:3000/reports?start_date=2022-08-01&finish_date=2022-08-02' > tmp/etalon.html
  def check_correctness
    puts "⏳ Checking correctness..."
    binding.pry
    result = get(FINISH_DATE_FOR_ETALON)
    etalon = File.read('tmp/etalon.html')
    if result == etalon
      puts '✅ Correctness test passed'
    else
      fail_with 'CORRECTNESS TEST FAILED'
    end
  end

  def get(finish_date)
    uri = URI("http://localhost:3000/reports?start_date=2022-08-01&finish_date=#{finish_date}")
    Net::HTTP.get_response(uri).body
  end

  def calculate_metric
    puts "⏳ Calculating metric with #{REPEATS} measurements..."
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
      fail_with "PERFORMANCE GOT WORSE: #{current_metric} > #{THRESHOLD_METRIC}"
    end
  end

  def check_approx_budget(current_metric)
    if current_metric < APPROX_BUDGET
      puts "✅ Approx metric < Approx budget: #{current_metric} < #{APPROX_BUDGET}"
    else
      fail_with "APPROX METRIC IS NOT GOOD ENOUGH: #{current_metric} > #{APPROX_BUDGET}"
    end
  end

  def check_final_buget
    puts "⏳ Now testing for final budget..."
    final_metric = get(FINAL_FINISH_DATE)
    if final_metric < FINAL_BUDGET
      puts "🎉 Success! The final metric is #{final_metric} < #{FINAL_BUDGET}"
    else
      fail_with "FINAL METRIC IS NOT GOOD ENOUGH: #{final_metric} > #{FINAL_BUDGET}"
    end
  end

  def fail_with(message)
    puts "❌ #{message}"
    exit(1)
  end
end
