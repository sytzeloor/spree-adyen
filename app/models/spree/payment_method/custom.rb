module Spree
  class PaymentMethod::Custom < PaymentMethod::Check
     def source_required?
      true
    end
  end
end
