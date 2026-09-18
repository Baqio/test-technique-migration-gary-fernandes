class ProductPrice::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  COLUMN_SEP = ";".freeze
  GRID_CODES = %w[DEPC CHR EXPO PART SALON].freeze

  def call
    # Gestion encodage ISO-8859-1 et détection ligne d'en-tête
    raw_lines = File.readlines(path, encoding: "ISO-8859-1:UTF-8")
    header_index = raw_lines.index { |line| line.start_with?("Ref;") }
    return unless header_index

    csv_content = raw_lines[header_index..].join

    CSV.parse(csv_content, headers: true, col_sep: COLUMN_SEP).each_with_index do |row, index|
      line_number = header_index + index + 2
      reference = N.text(row["Ref"])

      # Ignorer lignes vides, sous-totaux et catégories
      next if reference.nil? || reference.start_with?("---") || reference.start_with?("SOUS-TOTAL")

      vat_rate = N.decimal(row["TVA"]) || BigDecimal("20.0")

      # Idempotence : mise à jour ou création selon référence
      product = Product.find_or_initialize_by(reference: reference)
      product.update!(
        name:      N.text(row["Désignation"]),
        vintage:   N.vintage(row["Désignation"]),
        color:     N.color(row["Couleur"]),
        volume_ml: N.volume_ml(row["Contenant"]),
        vat_rate:  vat_rate,
        stock:     N.decimal(row["Stock"]).to_i
      )

      import_prices(product, row, vat_rate: vat_rate, line_number: line_number)
    end
  end

  private

  def import_prices(product, row, vat_rate:, line_number:)
    imported_prices_count = 0

    GRID_CODES.each do |grid_code|
      raw_price = row[grid_code]
      next if raw_price.nil? || raw_price.to_s.strip.empty?

      amount = N.decimal(raw_price)
      if amount.nil?
        report.add_warning(line_number: line_number, ref: product.reference, message: "Prix invalide pour la grille #{grid_code} (#{raw_price})")
        next
      end

      # Alerte si montant incohérent
      if amount <= 0
        report.add_warning(line_number: line_number, ref: product.reference, message: "Prix suspect (#{amount} €) pour la grille #{grid_code}")
      end

      # Conversion TTC -> HT selon TVA produit pour la grille EXPO
      amount_ht = grid_code == "EXPO" ? (amount / (1 + (vat_rate / BigDecimal("100")))).round(4) : amount

      price = ProductPrice.find_or_initialize_by(product: product, grid_code: grid_code)
      price.amount_ht = amount_ht
      price.save!

      imported_prices_count += 1
    end

    # Alerte si aucun prix renseigné
    if imported_prices_count.zero?
      report.add_warning(line_number: line_number, ref: product.reference, message: "Aucun tarif renseigné pour ce produit")
    end
  end
end
