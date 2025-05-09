directories %w[app spec config]

group :red_green_refactor, halt_on_fail: true do
  guard :rspec, failed_mode: :focus, cmd: "bundle exec rspec" do
    require "guard/rspec/dsl"
    dsl = Guard::RSpec::Dsl.new(self)

    # RSpec files
    rspec = dsl.rspec
    watch(rspec.spec_helper) { rspec.spec_dir }
    watch(rspec.spec_files)

    # Ruby files
    ruby = dsl.ruby
    dsl.watch_spec_files_for(ruby.lib_files)

    # Rails files
    rails = dsl.rails(view_extensions: %w[erb haml slim])
    dsl.watch_spec_files_for(rails.app_files)
    # dsl.watch_spec_files_for(rails.views)

    watch(rails.controllers) { |m| rspec.spec.call("requests/#{m[1]}_request") }

    # Rails config changes
    watch(rails.spec_helper) { rspec.spec_dir }
    watch(rails.routes) { "#{rspec.spec_dir}/routing" }
    watch(rails.app_controller) { "#{rspec.spec_dir}/requests" }

    # Jobs
    watch(%r{^app/jobs/(.+)\.rb$}) { |m| "#{rspec.spec_dir}/jobs/#{m[1]}_spec.rb" }
    # Our special folders
    watch(%r{^app/services/(.+)\.rb$}) { |m| "#{rspec.spec_dir}/services/#{m[1]}_spec.rb" }
    # components
    watch(%r{^app/components/(.+)rb$}) { |m| "spec/components/#{m[1]}_spec.rb" }
    watch(%r{^app/components/(.+)rb$}) { |m| "spec/components/#{m[1]}_system_spec.rb" }
  end
end
