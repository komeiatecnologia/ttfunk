require 'spec_helper'
require 'stringio'
require 'ttfunk/subset'

describe 'subsetting' do
  it 'consistently names font for same subsets' do
    font = TTFunk::File.open test_font('DejaVuSans')

    subset1 = TTFunk::Subset.for(font, :unicode)
    subset1.use(97)
    name1 = TTFunk::File.new(subset1.encode).name.strings[6]

    subset2 = TTFunk::Subset.for(font, :unicode)
    subset2.use(97)
    name2 = TTFunk::File.new(subset2.encode).name.strings[6]

    expect(name1).to eq name2
  end

  it 'changes font names for different subsets' do
    font = TTFunk::File.open test_font('DejaVuSans')

    subset1 = TTFunk::Subset.for(font, :unicode)
    subset1.use(97)
    name1 = TTFunk::File.new(subset1.encode).name.strings[6]

    subset2 = TTFunk::Subset.for(font, :unicode)
    subset2.use(97)
    subset2.use(98)
    name2 = TTFunk::File.new(subset2.encode).name.strings[6]

    expect(name1).to_not eq name2
  end

  it 'calculates checksum correctly for empty table data' do
    font = TTFunk::File.open test_font('Mplus1p')
    subset1 = TTFunk::Subset.for(font, :unicode)
    expect { subset1.encode }.to_not raise_error
  end

  it 'calculates correct search_range, entry_selector and range_shift values' do
    font = TTFunk::File.open test_font('DejaVuSans')

    subset = TTFunk::Subset.for(font, :unicode)
    subset.use(97)
    subset_io = StringIO.new(subset.encode)

    scaler_type, table_count = subset_io.read(6).unpack('Nn')
    search_range, entry_selector, range_shift = subset_io.read(6).unpack('nnn')

    # Subset fonts include 13 tables by default.
    expected_table_count = 13
    # Smallest power of two less than number of tables, times 16.
    expected_search_range = 8 * 16
    # Log2 of max power of two smaller than number of tables.
    expected_entry_selector = 3
    # Range shift is defined as 16*table_count - search_range.
    expected_range_shift = 16 * expected_table_count - expected_search_range

    expect(scaler_type).to eq(font.directory.scaler_type)
    expect(table_count).to eq(expected_table_count)
    expect(search_range).to eq(expected_search_range)
    expect(entry_selector).to eq(expected_entry_selector)
    expect(range_shift).to eq(expected_range_shift)
  end

  it 'knows which characters it includes' do
    font = TTFunk::File.open test_font('DejaVuSans')
    unicode = TTFunk::Subset.for(font, :unicode)
    unicode_8bit = TTFunk::Subset.for(font, :unicode_8bit)
    mac_roman = TTFunk::Subset.for(font, :mac_roman)
    windows1252 = TTFunk::Subset.for(font, :windows_1252)

    [unicode, unicode_8bit, mac_roman, windows1252].each do |subset|
      expect(subset.includes?(97)).to be_falsey
      subset.use(97)
      expect(subset.includes?(97)).to be_truthy
    end
  end
end
