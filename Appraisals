
RSPEC_VERSIONS = %w[3.8 3.9 3.10 3.11 3.12 3.13]

RSPEC_VERSIONS.each do |version|
  appraise "rspec-#{version}" do
    gem "rspec", "~> #{version}.0"
  end
end

appraise "rspec-4.0" do
  gem "rspec", "~> 4.0.0.beta1"
end
