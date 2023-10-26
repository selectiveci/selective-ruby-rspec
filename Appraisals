
RSPEC_VERSIONS = %w[3.8 3.9 3.10 3.11 3.12]

RSPEC_VERSIONS.each do |version|
  appraise "rspec-#{version}" do
    gem "rspec", "~> #{version}.0"
  end
end
