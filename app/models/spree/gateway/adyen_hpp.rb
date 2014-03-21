module Spree
  # Gateway for Adyen Hosted Payment Pages solution
  class Gateway::AdyenHPP < Gateway
    include AdyenCommon

    preference :skin_code, :string
    preference :shared_secret, :string

    def source_required?
      false
    end

    def auto_capture?
      false
    end

    # Spree usually grabs these from a Credit Card object but when using
    # Adyen Hosted Payment Pages where we wouldn't keep # the credit card object
    # as that entered outside of the store forms
    def actions
      %w{capture void credit}
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      !payment.void?
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      payment.pending? || payment.checkout?
    end

    def method_type
      'adyen'
    end

    def redirect_url(payment, adyen_confirmation_url)
      redirect_params = {
        currency_code: Spree::Config.currency,
        ship_before_date: Date.tomorrow,
        session_validity: 10.minutes.from_now,
        recurring: false,
        merchant_reference: "#{payment.order.number}-#{payment.id}",
        merchant_account: preferred_merchant_account,
        skin_code: preferred_skin_code,
        shared_secret: preferred_shared_secret,
        payment_amount: (payment.amount.to_f * 100).to_int
      }

      ::Adyen::Form.redirect_url(
        Rails.env.development? ?
          redirect_params.merge(resURL: adyen_confirmation_url) :
          redirect_params
      )
    end
  end
end
