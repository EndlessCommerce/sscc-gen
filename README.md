# sscc-gen

Serial Shipping Container Code (SSCC) Generator Ruby Gem

This gem provides an interface for generating SSCC codes.

See https://www.gs1-128.info/sscc-18/ for details

# How to use

```
class MySerialReferenceProvider
  # returns unique serial reference number using a database sequence
  def next
    MySerialReferenceModel
      .create
      .id
  end
end

sscc_gen = SsccGen::Generators::Sscc18.new({
  gs1_company_prefix: '0614141',
  extension_digit: 0, # optional - defaults to 0
  serial_reference_provider: MySerialReferenceProvider.new # implements #next
})

sscc = sscc_gen.generate # SsccGen::Result

if sscc.success?
  puts sscc.value.to_s
  # => (00) followed by 18 digits
else
  puts sscc.errors
end

# alternative

begin
  sscc = sscc_gen.generate!
  puts sscc.to_s
  # => (00) followed by 18 digits
rescue SsccGen::Error => e
  puts e
end
```
