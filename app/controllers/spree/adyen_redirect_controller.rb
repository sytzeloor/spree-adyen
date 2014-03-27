module Spree
  class AdyenRedirectController < StoreController
    before_filter :check_signature, only: :confirm

    def confirm
      if !authorized? && !pending?
        flash.notice = Spree.t(:payment_processing_failed)
        redirect_to checkout_state_path(order.state) and return
      end

      # cant set payment to complete here due to a validation
      # in order transition from payment to complete (it requires at
      # least one pending payment)
      payment.update!({ response_code: params[:pspReference] }) if payment.response_code != params[:pspReference]

      options = { test: !Rails.env.production? }

      if order.total == order.payment_total ||
        order.total == order.payments.where(state: %w(checkout pending processing complete)).map(&:amount).sum ||
        authorized?

        payment.log_entries.create!({ details: ActiveMerchant::Billing::Response.new(true, 'Completing order', params, options).to_yaml })

        order.update({ state: 'complete', completed_at: Time.now })
        order.finalize!

        if pending?
          flash.notice = Spree.t(:order_processed_but_pending)
        else
          flash.notice = Spree.t(:order_processed_successfully)
        end

        redirect_to order_path(order, token: order.token, google_tracker: true)
      else
        payment.log_entries.create!({ details: ActiveMerchant::Billing::Response.new(false, 'Returning to checkout', params, options).to_yaml })
        redirect_to checkout_state_path(order.state)
      end
    end

    private

    def order
      @order ||= current_order
    end

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

    def pending?
      params[:authResult] == "PENDING"
    end

    def success?
      params[:success] == 'true'
    end
  end
end
