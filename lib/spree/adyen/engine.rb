module Spree
  module Adyen
    class Engine < ::Rails::Engine
      engine_name "spree-adyen"

      isolate_namespace Spree::Adyen

      config.autoload_paths += %W(#{config.root}/lib)

      def self.activate
        Dir.glob(File.join(File.dirname(__FILE__), '../../../app/**/*_decorator*.rb')) do |c|
          Rails.configuration.cache_classes ? require(c) : load(c)
        end
      end

      config.to_prepare &method(:activate).to_proc

      initializer "spree.spree-adyen.payment_methods", :after => "spree.register.payment_methods" do |app|
        app.config.spree.payment_methods << Gateway::AdyenPayment
        app.config.spree.payment_methods << Gateway::AdyenHPP
      end
    end
  end
end
