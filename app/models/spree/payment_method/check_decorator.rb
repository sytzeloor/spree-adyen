module Spree
  PaymentMethod::Check.class_eval do
    def credit(credit_cents, response_code, gateway_options)
      response = {}
      def response.success?; true; end
      def response.authorization; ''; end

      response
    end
  end
end
