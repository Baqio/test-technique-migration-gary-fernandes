module Importer::Normalization
  module_function

  COUNTRY_MAP = {
    "FRANCE" => "FR",
    "BELGIQUE" => "BE",
    "SUISSE" => "CH",
    "LUXEMBOURG" => "LU",
    "ALLEMAGNE" => "DE",
    "ESPAGNE" => "ES",
    "ITALIE" => "IT"
  }.freeze

  def text(value)
    return nil if value.nil?

    str = value.to_s.gsub(/[[:space:]]+/, " ").strip
    str.empty? ? nil : str
  end

  def zip(value, country_code = "FR")
    return nil if value.nil?

    str = value.to_s.sub(/\.0$/, "").gsub(/[[:space:]]+/, "").strip
    return nil if str.empty?

    if country_code.to_s.upcase.start_with?("FR")
      case str.length
      when 2 then "#{str}000"
      when 4 then "0#{str}"
      else str
      end
    else
      str
    end
  end

  def country_code(value)
    return "FR" if value.blank?

    str = value.to_s.strip.upcase
    COUNTRY_MAP[str] || (str =~ /^[A-Z]{2}$/ ? str : nil)
  end

  def decimal(value)
    return nil if value.nil?

    str = value.to_s.gsub(/[[:space:]]+/, "").gsub(/[^\d,.-]/, "").tr(",", ".")
    return nil if str.empty?

    BigDecimal(str)
  rescue ArgumentError
    nil
  end

  def volume_ml(value)
    return nil if value.blank?

    str = value.to_s.strip

    case str
    when /(\d+(?:[.,]\d+)?)\s*ml/i
      BigDecimal($1.tr(",", ".")).to_i
    when /(\d+(?:[.,]\d+)?)\s*cl/i
      (BigDecimal($1.tr(",", ".")) * 10).round
    when /(\d+(?:[.,]\d+)?)\s*l\b/i
      (BigDecimal($1.tr(",", ".")) * 1000).round
    when /\b(?:6\s*x\s*|carton\s*\d*|btle|bouteille)?\s*(\d{2,3}(?:[.,]\d+)?)\b/i
      val = BigDecimal($1.tr(",", "."))
      val == 6 ? 750 : (val * 10).round
    else
      match = str.match(/(\d+(?:[.,]\d+)?)/)
      return nil unless match

      val = BigDecimal(match[1].tr(",", "."))
      val < 10 ? 750 : (val * 10).round
    end
  end

  def vintage(name)
    return nil if name.nil?

    name.to_s[/\b(19\d{2}|20\d{2})\b/]
  end

  def color(value)
    return nil if value.nil?

    str = value.to_s.strip
    return nil if str.empty?

    case str.downcase
    when "blanc" then "Blanc"
    when "rouge" then "Rouge"
    when "rosé", "rose" then "Rosé"
    else str.capitalize
    end
  end
end
