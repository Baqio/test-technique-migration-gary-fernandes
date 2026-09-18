require "roo"

class Customer::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  KINDS = {
    "CLIENT"   => "customer",
    "FOURN"    => "supplier",
    "PROSPECT" => "prospect",
    "P"        => "prospect",
    "C"        => "customer",
    "F"        => "supplier",
    "R"        => "customer"
  }.freeze

  def call
    sheet.each_with_index do |row, index|
      line_number = index + 1
      next if line_number == 1

      reference = N.text(row[0])
      company_name = N.text(row[3])
      last_name = N.text(row[1])
      first_name = N.text(row[2])

      next if reference.nil? || reference == "Code" || reference.start_with?("TOTAL")

      if last_name.nil? && first_name.nil? && company_name.nil?
        report.error(
          source: "Customer::Import::Cavegest",
          locator: "Ligne #{line_number} (Réf: #{reference})",
          message: "Nom, prénom et raison sociale manquants"
        )
        next
      end

      import_customer(row, reference: reference, last_name: last_name, first_name: first_name, company_name: company_name, line_number: line_number)
    end
  end

  private

  def sheet
    @sheet ||= Roo::Excelx.new(path).sheet(0)
  end

  def import_customer(row, reference:, last_name:, first_name:, company_name:, line_number:)
    country_code = N.country_code(row[7])

    ship_address1 = N.text(row[14])
    ship_country_code = N.country_code(row[17]) || "FR"
    ship_zip = N.zip(row[15], ship_country_code)
    ship_city = N.text(row[16])

    has_custom_shipping = ship_address1.present? || ship_city.present?
    use_billing = !has_custom_shipping

    unusable_val = row[26]
    unusable = unusable_val == 1 || unusable_val.to_s.strip.downcase == "oui" || unusable_val == true

    family_code = N.text(row[19])
    family_label = N.text(row[20])
    kind = KINDS[family_code] || KINDS[family_label] || "customer"

    customer = Customer.find_or_initialize_by(reference: reference)

    customer.assign_attributes(
      company_name:          company_name,
      last_name:             last_name,
      first_name:            first_name,
      address1:              N.text(row[4]),
      zip:                   N.zip(row[5], country_code),
      city:                  N.text(row[6]),
      country_code:          country_code,
      email:                 N.text(row[8]),
      phone:                 N.text(row[9]),
      use_billing_address:   use_billing,
      shipping_address1:     use_billing ? nil : ship_address1,
      shipping_zip:          use_billing ? nil : ship_zip,
      shipping_city:         use_billing ? nil : ship_city,
      shipping_country_code: use_billing ? nil : ship_country_code,
      kind:                  kind,
      customer_category:     family_label,
      price_grid_code:       N.text(row[21]),
      vat_number:            N.text(row[23]),
      excise_number:         N.text(row[24]),
      creation_date:         row[25].is_a?(String) ? Date.parse(row[25]) : row[25],
      active:                !unusable
    )

    unless customer.save
      report.error(
        source: "Customer::Import::Cavegest",
        locator: "Ligne #{line_number} (Réf: #{reference})",
        message: customer.errors.full_messages.join(", ")
      )
    end
  end
end
