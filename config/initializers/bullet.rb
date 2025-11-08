# frozen_string_literal: true

# Bullet configuration for detecting N+1 queries
if defined?(Bullet)
  Bullet.enable        = Rails.env.development?
  Bullet.bullet_logger = true
  Bullet.rails_logger  = true

  if Rails.env.development?
    # Don't raise on certain unused eager loading cases - these are known false positives
    # when associations are conditionally rendered but eager loading is still necessary
    # to prevent N+1 queries
    Bullet.raise = lambda { |notification|
      if notification.is_a?(Bullet::Notification::UnoptimizedQueryError)
        body = notification.body.to_s

        # Skip raising for Active Storage unused eager loading
        return false if body.include?("ActiveStorage::Attachment")

        # Skip raising for optional Tour associations that may not always be present
        # These are needed for tours that have them, preventing N+1 queries
        return false if body.include?("Tour => [:tour_add_ons]")
        return false if body.include?("Tour => [:weather_snapshots")
        return false if body.include?(":tour_add_ons]")
        return false if body.include?(":weather_snapshots")
      end

      true # Raise for all other Bullet notifications
    }
  end

  # Whitelist Active Storage associations as a fallback
  Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :blob

  # Whitelist optional Tour associations that are conditionally rendered
  Bullet.add_safelist type: :unused_eager_loading, class_name: "Tour", association: :weather_snapshots
  Bullet.add_safelist type: :unused_eager_loading, class_name: "Tour", association: :tour_add_ons

  # You can add more safelists here as needed
  # Bullet.add_safelist type: :n_plus_one_query, class_name: "Model", association: :association
end
