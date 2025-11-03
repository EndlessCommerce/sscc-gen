# frozen_string_literal: true

module SsccGen
  class SSCC
    DIGITS_REGEX = /\A\d{18}\z/ # 18 digits

    attr_reader :digits

    def initialize(digits)
      digits_str = digits.to_s
      raise Error, "SSCC must be 18 digits" unless DIGITS_REGEX.match?(digits_str)
      @digits = digits_str
    end

    # Returns AI formatted string including application identifier (00)
    def to_s
      "(00)#{digits}"
    end

    # Returns the check digit (last digit) as Integer
    def check_digit
      digits[-1].to_i
    end
  end
end
