# frozen_string_literal: true

require 'spree/money'

module Spree
  module ReportsHelper
    def report_order_cycle_options(order_cycles)
      order_cycles.map do |oc|
        orders_open_at = oc.orders_open_at&.to_s(:short) || 'NA'
        orders_close_at = oc.orders_close_at&.to_s(:short) || 'NA'
        ["#{oc.name} &nbsp; (#{orders_open_at} - #{orders_close_at})".html_safe, oc.id]
      end
    end

    def report_payment_method_options(orders)
      orders.map do |order|
        payment_method = order.payments.first&.payment_method

        next unless payment_method

        [payment_method.name, payment_method.id]
      end.compact.uniq
    end

    def report_shipping_method_options(orders)
      orders.map do |o|
        sm = o.shipping_method
        [sm&.name, sm&.id]
      end.uniq
    end

    def xero_report_types
      [[I18n.t(:summary), 'summary'],
       [I18n.t(:detailed), 'detailed']]
    end

    def currency_symbol
      Spree::Money.currency_symbol
    end
  end
end
