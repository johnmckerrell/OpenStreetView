# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_openstreetview.org_session',
  :secret      => '3dbb6b952a4ea6e23fbc24b135812d47b331ccdfb4c688dd33e563bd9674d1c2d260faccad231907f03a9bcb230965af93dae1b1279a7638a476eb90e2e3a4be'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
