namespace :vebra do
  desc "Retrieve all properties from Vebra and update persisted properties where possible"
  task :update_properties => :environment do
    Vebra.update_properties!
  end
end