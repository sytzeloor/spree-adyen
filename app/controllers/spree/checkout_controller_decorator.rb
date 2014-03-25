module Spree
  # Decorate the CheckoutController to make sure that when the user advances
  # from the payment step to the confirmation step, he is redirected to the
  # payment URL from Adyen to actually pay.
  #
  # Using this method we avoid using an iframe and make it seem Adyen is part
  # of our regular Spree workflow.
  #
  # This code is based on the Skrill example from spree_gateway.
  CheckoutController.class_eval do
    before_filter :confirm_adyen, only: [:update]

    private

    def confirm_adyen
      return unless params[:state] == 'payment' && params[:order][:payments_attributes]

      payment_method = Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])

      if payment_method.kind_of?(Gateway::AdyenHPP)
        @order.update!

        payment = @order.payments.where({ payment_method_id: payment_method.id, state: ['checkout', 'pending', 'processing'] }).first
        payment ||= @order.payments.create!({
          payment_method_id: payment_method.id,
          amount: @order.outstanding_balance
        })

        redirect_to payment_method.redirect_url(payment, adyen_confirmation_url)
      end
    end
  end
end
