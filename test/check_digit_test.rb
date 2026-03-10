# frozen_string_literal: true

require "test_helper"

class CheckDigitTest < Minitest::Test
  # Known GS1 SSCC check digits verified against the GS1 specification
  # Each pair is [17 data digits, expected check digit]
  KNOWN_CASES = [
    ["00061414100000001", 4],
    ["00061414100000010", 6],
    ["00061414100123456", 2],
    ["01234567890123456", 0],
    ["99999999999999999", 5],
    ["00000000000000000", 0],
    ["10000000000000000", 7],
  ].freeze

  def test_known_check_digits
    KNOWN_CASES.each do |data_digits, expected|
      actual = SsccGen::CheckDigit.compute(data_digits)
      assert_equal expected, actual,
        "CheckDigit.compute(#{data_digits.inspect}) expected #{expected}, got #{actual}"
    end
  end

  def test_result_is_always_single_digit
    KNOWN_CASES.each do |data_digits, _|
      result = SsccGen::CheckDigit.compute(data_digits)
      assert_includes 0..9, result
    end
  end

  def test_idempotent_recomputation
    KNOWN_CASES.each do |data_digits, expected|
      first  = SsccGen::CheckDigit.compute(data_digits)
      second = SsccGen::CheckDigit.compute(data_digits)
      assert_equal expected, first
      assert_equal first, second,
        "Recomputing check digit for #{data_digits.inspect} should be stable"
    end
  end

  def test_single_digit_input
    assert_equal 0, SsccGen::CheckDigit.compute("0")
    assert_equal 7, SsccGen::CheckDigit.compute("1")
  end
end
