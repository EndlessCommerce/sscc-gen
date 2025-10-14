# frozen_string_literal: true

module SsccGen
  class Result
    attr_reader :value, :errors

    def self.ok(value)
      new(success: true, value: value, errors: [])
    end

    def self.err(errors)
      errors_array = Array(errors).compact.map(&:to_s)
      new(success: false, value: nil, errors: errors_array)
    end

    def initialize(success:, value:, errors: [])
      @success = !!success
      @value = value
      @errors = Array(errors).compact.map(&:to_s).freeze
      freeze
    end

    def success?
      @success
    end
  end
end


