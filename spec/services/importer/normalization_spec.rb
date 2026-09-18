require "spec_helper"

RSpec.describe Importer::Normalization do
  describe ".text" do
    it "strips leading and trailing spaces" do
      expect(described_class.text("  Bonjour  ")).to eq("Bonjour")
    end

    it "returns nil for empty or whitespace-only string" do
      expect(described_class.text("   ")).to be_nil
      expect(described_class.text(nil)).to be_nil
    end
  end

  describe ".zip" do
    it "pads French postal codes with leading zeroes up to 5 digits" do
      expect(described_class.zip(4000)).to eq("04000")
      expect(described_class.zip("1000")).to eq("01000")
      expect(described_class.zip(4000.0)).to eq("04000")
      expect(described_class.zip("69002")).to eq("69002")
    end

    it "does not pad foreign postal codes" do
      expect(described_class.zip("1000", "BE")).to eq("1000")
    end

    it "returns nil for empty values" do
      expect(described_class.zip(nil)).to be_nil
      expect(described_class.zip("")).to be_nil
    end
  end

  describe ".decimal" do
    it "parses French formatted decimals with currency or percentages" do
      expect(described_class.decimal("  19,31 EUR")).to eq(BigDecimal("19.31"))
      expect(described_class.decimal("20%")).to eq(BigDecimal("20"))
      expect(described_class.decimal("13,32")).to eq(BigDecimal("13.32"))
    end

    it "returns nil for empty values" do
      expect(described_class.decimal(nil)).to be_nil
      expect(described_class.decimal("")).to be_nil
    end
  end

  describe ".volume_ml" do
    it "correctly converts container descriptions to millilitres" do
      expect(described_class.volume_ml("Bouteille - 75.0")).to eq(750)
      expect(described_class.volume_ml("½ Bouteille - 37.5")).to eq(375)
      expect(described_class.volume_ml("BIB - 300.0")).to eq(3000)
      expect(described_class.volume_ml("BIB - 500.0")).to eq(5000)
      expect(described_class.volume_ml("Litre - 100.0")).to eq(1000)
      expect(described_class.volume_ml("Magnum - 150.0")).to eq(1500)
      expect(described_class.volume_ml("6 x 75")).to eq(750)
      expect(described_class.volume_ml("Carton 6")).to eq(750)
    end
  end

  describe ".vintage" do
    it "extracts 4-digit years from designations" do
      expect(described_class.vintage("Coteaux Nord 2019")).to eq("2019")
      expect(described_class.vintage("Cuvée Marie 2023")).to eq("2023")
      expect(described_class.vintage("La Pierre Blanche")).to be_nil
    end
  end

  describe ".color" do
    it "normalizes wine colors" do
      expect(described_class.color("BLANC")).to eq("Blanc")
      expect(described_class.color("blanc")).to eq("Blanc")
      expect(described_class.color("Rouge")).to eq("Rouge")
      expect(described_class.color("rosé")).to eq("Rosé")
    end
  end

  describe ".country_code" do
    it "normalizes country names to 2-letter ISO codes" do
      expect(described_class.country_code("France")).to eq("FR")
      expect(described_class.country_code("FRANCE")).to eq("FR")
      expect(described_class.country_code("fr")).to eq("FR")
      expect(described_class.country_code("Belgique")).to eq("BE")
      expect(described_class.country_code("Allemagne")).to eq("DE")
      expect(described_class.country_code(nil)).to eq("FR")
    end
  end
end
