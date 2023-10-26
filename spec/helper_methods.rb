def define_a_context(&block)
  RSpec.context "a context" do
    instance_eval(&block)
  end
end

def define_a_spec
  it "should pass" do
    expect(true).to eq(true)
  end
end

# Given that we run selective-ruby's test suite with selective
# we have some unique constraints around what we can and cannot
# do without screwing up the actual test run. As such, we sometimes
# test private methods directly because testing their behaviors through
# public methods is not tenable.

# This method returns a subclass of the given class with all private
# instance methods made public.
def dirty_dirty_unprivate_class(klass)
  Class.new(klass) do
    (private_instance_methods - Class.private_instance_methods).each do |method|
      eval <<-RUBY
        def #{method}(...)
          super
        end
      RUBY
    end
  end
end
