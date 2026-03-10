# frozen_string_literal: true

module SsccGen
  class CheckDigit
    # GS1 Mod 10 (weight 3,1 from rightmost data digit)
    def self.compute(data_digits)
      digits = data_digits.chars.map(&:to_i)
      sum = digits.reverse.each_with_index.sum do |d, i|
        weight = (i.even? ? 3 : 1)
        d * weight
      end
      (10 - (sum % 10)) % 10
    end
  end
end
