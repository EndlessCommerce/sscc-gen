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

  def test_long_prefixes_up_to_twelve_digits
    [11, 12].each do |prefix_len|
      prefix = "614141234567"[0, prefix_len]
      gen = SsccGen::Generators::Sscc18.new(
        gs1_company_prefix: prefix,
        extension_digit: 3,
        serial_reference_provider: DeterministicProvider.new(["7"])
      )

      result = gen.generate
      assert result.success?, "Expected success for #{prefix_len}-digit prefix, got: #{result.errors.inspect}"

      sscc = result.value
      allowed_serial_len = 16 - prefix_len
      assert_equal "3#{prefix}#{'0' * (allowed_serial_len - 1)}7", sscc.digits[0, 17]
      assert_equal compute_check_digit(sscc.digits[0, 17]), sscc.check_digit
    end
  end

  def test_thirteen_digit_prefix_rejected
    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "6141412345678",
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new(["1"])
    )
    refute gen.generate.success?
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

    # serial too long - should error
    long_serial = "12345678901234567890" # 20 digits
    gen4 = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "0614141",
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new([long_serial])
    )
    result = gen4.generate
    refute result.success?, "Expected error for overflowing serial reference"
    assert result.errors.any? { |e| e.include?("exceeds maximum length") }
  end

  def test_bang_variant_raises
    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: "ABC",
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new(["1"]) 
    )
    assert_raises(SsccGen::Error) { gen.generate! }
  end

  def test_serial_reference_overflow_raises_error_at_max_prefix_len
    # With MAX_PREFIX_LEN (10), allowed_serial_len = 6
    # Serial longer than 6 digits should raise an error instead of silently truncating
    prefix = "1" * 10 # MAX_PREFIX_LEN
    long_serial = "123456789012345" # 15 digits, exceeds allowed 6

    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: prefix,
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new([long_serial])
    )

    result = gen.generate
    refute result.success?, "Expected error for overflowing serial reference"
    assert result.errors.any? { |e| e.include?("exceeds maximum length") }
  end

  def test_max_serial_within_allowed_length_succeeds
    prefix = "1" * 10 # MAX_PREFIX_LEN, allowed_serial_len = 6
    max_serial = "999999" # exactly 6 digits — should succeed

    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: prefix,
      extension_digit: 0,
      serial_reference_provider: DeterministicProvider.new([max_serial])
    )

    result = gen.generate
    assert result.success?, "Expected success for serial within allowed length, got: #{result.errors.inspect}"
    serial_slice = result.value.digits[1 + prefix.length, 6]
    assert_equal(max_serial, serial_slice)
  end

  def test_overflow_raises_when_serial_exceeds_allowed_length
    prefix = "1" * 10 # 10-digit prefix → allowed_serial_len = 6 (max serial: 999,999)
    overflow_serial = "1010454" # 7 digits, exceeds allowed 6

    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: prefix,
      serial_reference_provider: DeterministicProvider.new([overflow_serial])
    )

    error = assert_raises(SsccGen::Error) { gen.generate! }
    assert_match(/exceeds maximum length/, error.message)
  end

  def test_overflow_accepts_serial_within_allowed_length
    prefix = "1" * 10 # 10-digit prefix → allowed_serial_len = 6
    serial = "999999" # exactly 6 digits

    gen = SsccGen::Generators::Sscc18.new(
      gs1_company_prefix: prefix,
      serial_reference_provider: DeterministicProvider.new([serial])
    )

    sscc = gen.generate!
    assert_instance_of SsccGen::SSCC, sscc
  end

  private

  def compute_check_digit(data_digits)
    digits = data_digits.chars.map(&:to_i)
    sum = digits.reverse.each_with_index.sum { |d, i| d * (i.even? ? 3 : 1) }
    (10 - (sum % 10)) % 10
  end
end


