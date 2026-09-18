require "bigdecimal"

module Importer::Normalization
  module_function

  COUNTRY_MAP = {
    "FRANCE" => "FR",
    "FR"     => "FR"
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
      when 2 then "#{str}000" # Ex: 78 -> 78000
      when 4 then "0#{str}"   # Ex: 4000 -> 04000, 1000 -> 01000
      else str
      end
    else
      str
    end
  end

  def country_code(value)
    return nil if value.nil?

    str = value.to_s.strip.upcase
    return nil if str.empty?

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
    return nil if value.nil?

    str = value.to_s.strip
    return nil if str.empty?

    case str
    when /(\d+(?:[.,]\d+)?)\s*ml/i
      (BigDecimal($1.tr(",", "."))).to_i
    when /(\d+(?:[.,]\d+)?)\s*cl/i
      (BigDecimal($1.tr(",", ".")) * 10).to_i
    when /(\d+(?:[.,]\d+)?)\s*l\b/i
      (BigDecimal($1.tr(",", ".")) * 1000).to_i
    when /\b(?:6\s*x\s*)?(\d{2,3})\b/ # Cas standard "75" ou "6x75" (exprimé en cl)
      $1.to_i * 10
    else
      num = str[/\d+(?:[.,]\d+)?/]
      return nil unless num

      val = BigDecimal(num.tr(",", "."))
      val < 10 ? (val * 1000).to_i : (val * 10).to_i
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