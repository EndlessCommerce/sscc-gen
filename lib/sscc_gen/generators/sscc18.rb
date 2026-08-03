# frozen_string_literal: true

module SsccGen
  module Generators
    class Sscc18
      MIN_PREFIX_LEN = 6
      MAX_PREFIX_LEN = 12

      def initialize(gs1_company_prefix:, serial_reference_provider:, extension_digit: 0)
        @gs1_company_prefix = gs1_company_prefix
        @serial_reference_provider = serial_reference_provider
        @extension_digit = extension_digit
      end

      def generate
        errors = validate_inputs
        return Result.err(errors) unless errors.empty?

        serial_reference = next_serial_reference
        return Result.err("serial reference must be digits") unless serial_reference.match?(/\A\d+\z/)

        allowed_serial_len = 16 - @gs1_company_prefix.length
        if serial_reference.length > allowed_serial_len
          raise Error, "serial reference '#{serial_reference}' exceeds maximum length of #{allowed_serial_len} " \
                       "digits for GS1 company prefix of length #{@gs1_company_prefix.length}"
        end

        data_digits = [@extension_digit.to_s, @gs1_company_prefix, serial_reference.rjust(allowed_serial_len, '0')].join
        check = CheckDigit.compute(data_digits)
        sscc_digits = data_digits + check.to_s

        Result.ok(SSCC.new(sscc_digits))
      rescue Error => e
        Result.err(e.message)
      end

      def generate!
        result = generate
        return result.value if result.success?
        raise Error, Array(result.errors).join(", ")
      end

      private

      def validate_inputs
        errors = []
        prefix = @gs1_company_prefix.to_s
        errors << "gs1_company_prefix must be digits" unless prefix.match?(/\A\d+\z/)
        errors << "gs1_company_prefix length must be #{MIN_PREFIX_LEN}..#{MAX_PREFIX_LEN}" unless (MIN_PREFIX_LEN..MAX_PREFIX_LEN).cover?(prefix.length)
        @gs1_company_prefix = prefix

        begin
          @extension_digit = Integer(@extension_digit)
        rescue ArgumentError, TypeError
          errors << "extension_digit must be an Integer 0..9"
        end
        errors << "extension_digit must be 0..9" unless (0..9).cover?(@extension_digit)

        unless @serial_reference_provider && @serial_reference_provider.respond_to?(:next)
          errors << "serial_reference_provider must respond to #next"
        end

        errors
      end

      def next_serial_reference
        value = @serial_reference_provider.next
        value.to_s
      end
    end
  end
end
