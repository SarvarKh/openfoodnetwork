class StandingOrderPlacementJob
  attr_accessor :order_cycle

  def initialize(order_cycle)
    @order_cycle = order_cycle
  end

  def perform
    proxy_orders.each do |proxy_order|
      proxy_orders.initialise_order!
      process(proxy_order.order)
    end
  end

  private

  def proxy_orders
    ProxyOrder.not_canceled.where(order_cycle_id: order_cycle)
    .merge(StandingOrder.active).joins(:standing_order)
  end

  def process(order)
    return if order.completed?
    changes = cap_quantity_and_store_changes(order) unless order.completed?
    until order.completed?
      unless order.next!
        Bugsnag.notify(RuntimeError.new("StandingOrderPlacementError"), {
          job: "StandingOrderPlacement",
          error: "Cannot process order due to errors",
          data: {
            order_number: order.number,
            errors: order.errors.full_messages
          }
        })
        break
      end
    end
    send_placement_email(order, changes)
  end

  def cap_quantity_and_store_changes(order)
    insufficient_stock_lines = order.insufficient_stock_lines
    return {} unless insufficient_stock_lines.present?
    insufficient_stock_lines.each_with_object({}) do |line_item, changes|
      changes[line_item.id] = line_item.quantity
      line_item.cap_quantity_at_stock!
    end
  end

  def send_placement_email(order, changes)
    return unless order.completed?
    Spree::OrderMailer.standing_order_email(order, 'placement', changes).deliver
  end
end
