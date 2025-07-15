namespace :db do
  namespace :seed do
    # Convention: seed file is named as rake task and located under db/seeds
    def seed_for(source)
      load(File.join(Rails.root, 'db', 'seeds', "#{source}.rb"))
    end

    task hicaps_items: :environment do
      seed_for('hicaps_items')
    end

    task admin_users: :environment do
      seed_for('admin_users')
    end

    task subscription_plans: :environment do
      seed_for('subscription_plans')
    end

    task notification_types: :environment do
      seed_for('notification_types')
    end

    task all: [:subscription_plans, :hicaps_items, :notification_types]
  end
end
