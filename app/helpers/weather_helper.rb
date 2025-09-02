module WeatherHelper
  def degree(temperature)
    "#{to_fahrenheit(temperature)}&deg;F".html_safe
  end

  def to_fahrenheit(celsius)
    (1.8 * celsius + 32).to_i
  end
end
