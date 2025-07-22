namespace :splose do |args|
  # NOTE: this should be run after `import_contacts` and `import_patients` tasks
  # bin/rails splose:import_associated_contacts business_id=1 api_key=xxx
  task import_associated_contacts: :environment do
  end
end