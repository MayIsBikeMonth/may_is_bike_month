# 2023 was run as a spreadsheet (not on this app) - winner was whoever rode
# the most miles. This imports the archived totals as a legacy competition.
# Source: https://docs.google.com/spreadsheets/d/1wk8oUY1yx8wFn2GaCd-Yw121fGVkiFf8oJJJJdiS8PU
METERS_PER_MILE = 1609.344
METERS_PER_FOOT = 0.3048

# [name, [mi_w1, ft_w1, mi_w2, ft_w2, mi_w3, ft_w3, mi_w4, ft_w4, mi_w5, ft_w5, total_mi, total_ft]]
LEGACY_2023_ROWS = [
  ["Noah", 644.8, 32_580, 424.4, 19_656, 246.9, 14_298, 291.4, 23_700, 225.5, 14_390, 1833, 104_624],
  ["Katya", 150.1, 14_400, 286.7, 26_105, 196.5, 17_543, 683, 32_575, 213.8, 12_129, 1530, 102_752],
  ["Jackson", 70.2, 8_360, 180.9, 17_854, 207.9, 14_839, 588.9, 29_350, 0.0, 0, 1048, 70_403],
  ["Yvonne", 75, 3_888, 176.6, 12_421, 149.1, 9_422, 76.8, 1_660, 134.2, 5_885, 612, 33_276],
  ["Seth", 95.1, 6_945, 191.2, 14_939, 192.6, 13_451, 59.9, 2_790, 36.8, 4_124, 576, 42_249],
  ["Chris", 143.1, 13_793, 68.3, 7_083, 44.7, 4_261, 133, 5_725, 118.5, 2_503, 508, 33_365],
  ["Danny", 56.17, 3_694, 135.2, 7_470, 49.3, 3_496, 34.6, 2_776, 141.9, 6_755, 417, 24_191],
  ["Zack", 107.1, 5_751, 85.1, 5_938, 144.5, 7_237, 54.9, 3_383, 5.3, 148, 397, 22_457],
  ["Gabby", 99.8, 0, 110.4, 0, 123.5, 0, 40.7, 0, 0, 0, 374, 0],
  ["Sam", 194.6, 14_114, 41.8, 1_707, 12, 447, 79.8, 1_362, 0.0, 0, 328, 17_630],
  ["Brittany", 29.7, 505, 0, 0, 61.7, 1_265, 85, 1_286, 56.8, 561, 233, 3_617],
  ["Elizabeth", 128.5, 8_197, 66.9, 3_154, 15.2, 1_332, 0, 0, 0.0, 0, 211, 12_683],
  ["Lily B", 35.1, 0, 3, 0, 43, 0, 49, 0, 7.0, 0, 137, 0],
  ["Ravi", 0, 0, 42, 3_376, 59, 2_070, 31.7, 1_663, 0.0, 0, 133, 7_109],
  ["Ali", 24.3, 1_013, 17.7, 875, 10.7, 505, 61.1, 2_876, 4.6, 229, 118, 5_498],
  ["Maura", 7.6, 456, 29, 591, 14.2, 665, 10.3, 400, 0.0, 0, 61, 2_112],
  ["Jeremy", 0, 0, 0, 0, 2.1, 114, 36.2, 1_675, 0, 0, 38, 1_789],
  ["Gar", 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 0],
  ["Steve", 0, 0, 22.7, 2_284, 0, 0, 0, 0, 0, 0, 23, 2_284]
].freeze

competition = Competition.find_or_initialize_by(start_date: Date.new(2023, 5, 1))
competition.end_date = Date.new(2023, 5, 31)
competition.display_name = "MIBM 2023"
competition.kind = :legacy
competition.save!

periods = competition.periods

LEGACY_2023_ROWS.each do |row|
  name = row[0]
  weekly_values = row[1, 10]
  total_miles, total_feet = row[11], row[12]

  period_data = periods.each_with_index.map do |period, index|
    miles = weekly_values[index * 2]
    feet = weekly_values[index * 2 + 1]
    period.merge(
      dates: [],
      distance: (miles * METERS_PER_MILE).round(2),
      elevation: (feet * METERS_PER_FOOT).round(2),
      ids: []
    )
  end

  score_data = {
    dates: [],
    distance: (total_miles * METERS_PER_MILE).round(2),
    elevation: (total_feet * METERS_PER_FOOT).round(2),
    ids: [],
    periods: period_data
  }.as_json

  user = LegacyUserFinder.find_or_create(name)
  competition_user = CompetitionUser.find_or_initialize_by(competition:, user:)
  competition_user.included_in_competition = true
  competition_user.display_name = name
  competition_user.score_data = score_data
  competition_user.save!
end
