# frozen_string_literal: true

require "test_helper"

class DeterministicProvider
  def initialize(values)
    @values = Array(values).dup
  end

  def next
    @values.shift.to_s
  end
end

class Sscc18Test < Minitest::Test
  def test_generates_valid_sscc_and_ai_string
    provider = DeterministicProvider.new(["123456"]) # 6 digits → will be left-padded to 9
    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "0614141",
      extension_digit: 0,
      serial_reference_provider: provider
    )

    result = gen.generate
    assert result.success?, "Expected success, got errors: #{result.errors.inspect}"

    sscc = result.value
    assert_match(/\A\(00\)\d{18}\z/, sscc.to_s)
    assert_match(/\A\d{18}\z/, sscc.digits)

    # Check digit correctness
    data_digits = sscc.digits[0, 17]
    expected_check = compute_check_digit(data_digits)
    assert_equal expected_check, sscc.check_digit
  end

  def test_zero_padding_of_serial_reference
    provider = DeterministicProvider.new(["1"]) # will be padded
    prefix = "0614141"
    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: prefix,
      extension_digit: 0,
      serial_reference_provider: provider
    )
    sscc = gen.generate.value

    allowed_serial_len = 16 - prefix.length
    serial_slice = sscc.digits[1 + prefix.length, allowed_serial_len]
    assert_equal("0" * (allowed_serial_len - 1) + "1", serial_slice)
  end

  def test_validation_errors
    # bad prefix
    gen1 = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "ABC",
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new(["1"]) 
    )
    refute gen1.generate.success?

    # bad extension
    gen2 = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "0614141",
      extension_digit: 12,
      serial_reference_provider: DeterministicProvider.new(["1"]) 
    )
    refute gen2.generate.success?

    # provider missing #next
    gen3 = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "0614141",
      extension_digit: 0,
      serial_reference_provider: Object.new
    )
    refute gen3.generate.success?

    # serial too long - should truncate
    long_serial = "12345678901234567890" # 20 digits
    gen4 = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "0614141",
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new([long_serial])
    )
    result = gen4.generate
    assert result.success?, "Expected success after truncation, got errors: #{result.errors.inspect}"
    # With 7-digit prefix, allowed_serial_len = 9, so should take last 9 digits: "234567890"
    serial_slice = result.value.digits[1 + 7, 9]
    assert_equal("234567890", serial_slice)
  end

  def test_bang_variant_raises
    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "ABC",
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new(["1"]) 
    )
    assert_raises(SsccGen::Error) { gen.generate! }
  end

  def test_serial_reference_truncation_ensures_overflow_at_max_prefix_len
    # With MAX_PREFIX_LEN (10), allowed_serial_len = 6
    # Serial should be truncated to trailing 6 digits, ensuring overflow at 10^6
    prefix = "1" * 10 # MAX_PREFIX_LEN
    long_serial = "123456789012345" # 15 digits
    
    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: prefix,
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new([long_serial])
    )
    
    result = gen.generate
    assert result.success?, "Expected success after truncation, got errors: #{result.errors.inspect}"
    
    # Should take last 6 digits: "012345"
    allowed_serial_len = 16 - prefix.length # 6
    serial_slice = result.value.digits[1 + prefix.length, allowed_serial_len]
    assert_equal("012345", serial_slice, "Serial should be truncated to trailing 6 digits")
    
    # Verify that when serial reaches max (999999), next would overflow to 000000
    max_serial = "999999"
    gen2 = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: prefix,
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new(["123456789012345#{max_serial}"]) # ends with 999999
    )
    
    result2 = gen2.generate
    assert result2.success?
    serial_slice2 = result2.value.digits[1 + prefix.length, allowed_serial_len]
    assert_equal(max_serial, serial_slice2, "Max serial should fit within 6 digits")
  end

  private

  def compute_check_digit(data_digits)
    digits = data_digits.chars.map(&:to_i)
    sum = digits.reverse.each_with_index.sum { |d, i| d * (i.odd? ? 3 : 1) }
    (10 - (sum % 10)) % 10
  end
end


