module Spree
  class AdyenRedirectController < StoreController
    before_filter :check_signature, only: :confirm

    def confirm
      order = current_order

      unless authorized?
        flash.notice = Spree.t(:payment_processing_failed)
        redirect_to checkout_state_path(order.state) and return
      end

      # cant set payment to complete here due to a validation
      # in order transition from payment to complete (it requires at
      # least one pending payment)
      payment.update!({ response_code: params[:pspReference] }) if payment_method.response_code != params[:pspReference]

      order.next

      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        redirect_to order_path(order, token: order.token)
      else
        redirect_to checkout_state_path(order.state)
      end
    end

    private
      def check_signature
        unless ::Adyen::Form.redirect_signature_check(params, payment_method.preferred_shared_secret)
          raise "Payment Method not found."
        end
      end

      def payment
        payment_id = params[:merchantReference].split('-')[-1]
        @payment ||= current_order.payments.find(payment_id)
      end

      def payment_method
        @payment_method ||= payment.payment_method
      end

      def authorized?
        params[:authResult] == "AUTHORISED"
      end
  end
end
